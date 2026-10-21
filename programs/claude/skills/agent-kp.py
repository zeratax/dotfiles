"""agent-kp: let an agent find KeePassXC entries and use their passwords
without ever seeing them.

Talks to the running KeePassXC over the Secret Service D-Bus API, so KeePassXC
itself does the unlocking (quick unlock: face auth or the OS password) and,
with "Confirm when passwords are retrieved by clients", asks before handing
out each password. On top of that, every `run` shows a dialog with the entry,
the command and the agent's reason.

Searching only reads entry labels and attributes (path, username, URL), never
secrets. A password goes to the command via an env var, stdin or a 0600 tmpfs
file, never argv, and anything the command prints has it replaced by ********.
This keeps honest mistakes from leaking secrets; it is not a sandbox.
"""

import argparse
import html
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import threading

import secretstorage

KDIALOG = "@kdialog@"
MASK = b"********"
SHOWN = ("Path", "UserName", "URL")


def die(msg, code=2):
    print(f"agent-kp: {msg}", file=sys.stderr)
    sys.exit(code)


def session_env():
    # agents' shells don't inherit the graphical session; point at it
    run = os.environ.setdefault("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    os.environ.setdefault("WAYLAND_DISPLAY", "wayland-0")
    os.environ.setdefault("DBUS_SESSION_BUS_ADDRESS", f"unix:path={run}/bus")
    os.environ.setdefault("QT_QPA_PLATFORM", "wayland")


def collections(conn):
    try:
        cols = list(secretstorage.get_all_collections(conn))
    except secretstorage.exceptions.SecretServiceNotAvailableException:
        die("no Secret Service on the session bus (is KeePassXC running?)")
    if not cols:
        die("no collections: expose a group in KeePassXC's database settings")
    for col in cols:
        if col.is_locked() and col.unlock():
            die("unlock dismissed by user", 126)
    return cols


def entries(conn):
    for col in collections(conn):
        for item in col.get_all_items():
            attrs = item.get_attributes()
            attrs.setdefault("Path", item.get_label())
            yield item, attrs


def describe(attrs):
    return "\t".join(attrs.get(k, "") for k in SHOWN)


def find_one(conn, name):
    found = [
        (i, a)
        for i, a in entries(conn)
        if name in (a.get("Path"), a.get("Title"), a.get("Uuid"))
    ]
    if not found:
        die(f"no such entry: {name} (try: agent-kp search)")
    if len(found) > 1:
        paths = "\n  ".join(a["Path"] for _, a in found)
        die(f"{name} is ambiguous, use the full path:\n  {paths}")
    return found[0]


def q(s):
    # quote like a shell would and escape anything non-ASCII, so bidi
    # overrides or zero-width characters can't disguise the dialog text
    s = shlex.quote(s)
    return s.encode("ascii", "backslashreplace").decode()


def approve(path, how, argv, reason):
    text = (
        f"<html><b>Use the password of</b> <tt>{html.escape(q(path))}</tt><br>"
        f"<b>passed via:</b> {html.escape(how)}<br><br>"
        "<b>to run:</b><pre style='white-space:pre-wrap'>"
        f"{html.escape(' '.join(q(a) for a in argv))}</pre>"
        f"<b>in:</b> <tt>{html.escape(q(os.getcwd()))}</tt><br><br>"
        f"<b>Why:</b><br>{html.escape(reason).replace(chr(10), '<br>')}</html>"
    )
    r = subprocess.run(
        [KDIALOG, "--title", "Agent requests a KeePass password",
         "--warningyesno", text, "--yes-label", "Allow", "--no-label", "Deny"],
        stderr=subprocess.DEVNULL,
    )
    if r.returncode != 0:
        die("denied by user", 126)


def masked(src, dst, secret):
    pieces = [p for p in secret.split(b"\n") if len(p) >= 4]
    for line in iter(src.readline, b""):
        for p in pieces:
            line = line.replace(p, MASK)
        dst.write(line)
        dst.flush()


def cmd_search(conn, args):
    term = args.term.casefold()
    for _, a in sorted(entries(conn), key=lambda e: e[1]["Path"]):
        if any(term in a.get(k, "").casefold() for k in ("Path",) + SHOWN):
            print(describe(a))


def cmd_ls(conn, args):
    prefix = "/" + args.group.strip("/") + "/" if args.group else "/"
    for path in sorted(a["Path"] for _, a in entries(conn)):
        if path.startswith(prefix) or not args.group:
            print(path)


def cmd_info(conn, args):
    _, a = find_one(conn, args.entry)
    for k in SHOWN:
        print(f"{k}: {a.get(k, '')}")


def cmd_run(conn, args):
    argv = args.command
    if argv and argv[0] == "--":
        argv = argv[1:]
    if not argv:
        die("run: no command given (put it after --)")
    prog = shutil.which(argv[0])
    if not prog:
        die(f"run: command not found: {argv[0]}")
    if args.stdin:
        how = "stdin"
    elif args.file:
        how = f"a temporary file (${args.file})"
    else:
        how = f"environment variable ${args.env}"
    for var in (args.file, args.env):
        if var and not var.isidentifier():
            die(f"run: bad variable name {var}")

    item, a = find_one(conn, args.entry)
    approve(a["Path"], how, [os.path.realpath(prog)] + argv[1:], args.reason)
    try:
        secret = item.get_secret()  # KeePassXC asks here if confirmation is on
    except secretstorage.exceptions.PromptDismissedException:
        die("denied in KeePassXC", 126)
    if not secret:
        die(f"{a['Path']} has an empty password")

    env = dict(os.environ)
    stdin = None
    tmp = None
    try:
        if args.stdin:
            stdin = subprocess.PIPE
        elif args.file:
            fd, tmp = tempfile.mkstemp(
                prefix="agent-kp.", dir=os.environ["XDG_RUNTIME_DIR"])
            with os.fdopen(fd, "wb") as f:
                f.write(secret)
            env[args.file] = tmp
        else:
            env[args.env] = secret.decode()
        proc = subprocess.Popen(
            [prog] + argv[1:], env=env, stdin=stdin,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        threads = [
            threading.Thread(target=masked, args=(s, d, secret))
            for s, d in ((proc.stdout, sys.stdout.buffer),
                         (proc.stderr, sys.stderr.buffer))
        ]
        for t in threads:
            t.start()
        if args.stdin:
            try:
                proc.stdin.write(secret + b"\n")
                proc.stdin.close()
            except BrokenPipeError:
                pass
        rc = proc.wait()
        for t in threads:
            t.join()
        return rc
    finally:
        if tmp:
            os.unlink(tmp)


def main():
    p = argparse.ArgumentParser(
        prog="agent-kp",
        description="Use KeePassXC passwords without seeing them. Exit 126 "
        "means Jona denied or dismissed a prompt.")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("search", help="entries matching a term "
                       "(path, username, URL; tab-separated)")
    s.add_argument("term")
    s = sub.add_parser("ls", help="entry paths, optionally under a group")
    s.add_argument("group", nargs="?")
    s = sub.add_parser("info", help="path, username and URL of an entry")
    s.add_argument("entry", help="full path, title or UUID")
    s = sub.add_parser("run", help="run a command with an entry's password")
    s.add_argument("--entry", required=True, help="full path, title or UUID")
    s.add_argument("--reason", required=True, help="why, shown to Jona")
    how = s.add_mutually_exclusive_group()
    how.add_argument("--env", metavar="NAME", default="SECRET",
                     help="export it as $NAME (default: SECRET)")
    how.add_argument("--stdin", action="store_true",
                     help="feed it (plus newline) on stdin")
    how.add_argument("--file", metavar="NAME",
                     help="0600 tmpfs file, its path exported as $NAME")
    s.add_argument("command", nargs=argparse.REMAINDER)
    args = p.parse_args()

    session_env()
    conn = secretstorage.dbus_init()
    try:
        rc = {"search": cmd_search, "ls": cmd_ls, "info": cmd_info,
              "run": cmd_run}[args.cmd](conn, args)
    finally:
        conn.close()
    sys.exit(rc or 0)


if __name__ == "__main__":
    main()

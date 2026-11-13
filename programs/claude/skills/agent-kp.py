"""agent-kp: let an agent find KeePassXC entries and use their passwords
without ever seeing them.

Talks to the running KeePassXC over the Secret Service D-Bus API, so KeePassXC
itself does the unlocking (quick unlock: face auth or the OS password) and,
with "Confirm when passwords are retrieved by clients", asks before handing
out a password. KeePassXC remembers that answer per D-Bus connection only, so
`run` and `forget` go through a user service (`agent-kp serve`, started by
systemd on the first connection to $XDG_RUNTIME_DIR/agent-kp.sock) that holds
one connection for the whole login. `search`, `ls` and `info` only read
attributes and talk to KeePassXC directly.

For every `run` the service shows a dialog with the entry, the command, the
caller and the agent's reason. "Allow for 6 h" skips that dialog for the entry
(any command) for 6 hours, for the asking session only, and lives in the
service's memory. The caller's cwd, environment and parent processes come
from /proc of the connecting process, or from what it says itself where /proc
is unreadable. Every decision goes to the journal before any password is
fetched (`journalctl --user -t agent-kp`); users can't delete or edit their
journal entries there.

Searching only reads entry labels and attributes (path, username, URL), never
secrets. A password goes to the command via an env var, stdin or a 0600 tmpfs
file, never argv, and anything the command prints has it replaced by ********.
This keeps honest mistakes from leaking secrets; it is not a sandbox.
"""

import argparse
import base64
import contextlib
import glob
import html
import json
import os
import re
import select
import shlex
import shutil
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time
import traceback

import secretstorage
from systemd import daemon, journal

DIALOG = "@dialog@"
MASK = b"********"
SHOWN = ("Path", "UserName", "URL")
CALLER_ENV = ("CLAUDE_CODE_SESSION_ID", "CLAUDE_CODE_HOST_SESSION_ID", "AI_AGENT")
REMEMBER_HOURS = 6
TIMEOUT = 15 * 60  # for Jona's answer, in our dialog or in KeePassXC's
NO_SERVICE = "no Secret Service on the session bus (is KeePassXC running?)"


class Fail(Exception):
    """An error for the agent, with the exit code to use."""

    def __init__(self, msg, code=2):
        super().__init__(msg)
        self.code = code


def session_env():
    # agents' shells don't inherit the graphical session; point at it
    run = os.environ.setdefault("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    os.environ.setdefault("WAYLAND_DISPLAY", "wayland-0")
    os.environ.setdefault("DBUS_SESSION_BUS_ADDRESS", f"unix:path={run}/bus")
    os.environ.setdefault("QT_QPA_PLATFORM", "wayland")


def socket_path():
    return os.path.join(os.environ["XDG_RUNTIME_DIR"], "agent-kp.sock")


def collections(conn):
    try:
        cols = list(secretstorage.get_all_collections(conn))
        if not cols:
            raise Fail("no collections: expose a group in KeePassXC's database settings")
        for col in cols:
            if col.is_locked() and col.unlock(timeout=TIMEOUT):
                raise Fail("unlock dismissed by user", 126)
    except secretstorage.exceptions.SecretServiceNotAvailableException:
        raise Fail(NO_SERVICE)
    except TimeoutError:
        raise Fail("no answer in KeePassXC, timed out", 126)
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
        raise Fail(f"no such entry: {name} (try: agent-kp search)")
    if len(found) > 1:
        paths = "\n  ".join(a["Path"] for _, a in found)
        raise Fail(f"{name} is ambiguous, use the full path:\n  {paths}")
    return found[0]


def fetch(item):
    # KeePassXC keeps each item locked per client until it confirms the access
    # (its prompt comes from unlocking the item); denied, it stays locked
    if item.is_locked():
        item.unlock(timeout=TIMEOUT)
    return item.get_secret()


def q(s):
    # quote like a shell would and escape anything non-ASCII, so bidi
    # overrides or zero-width characters can't disguise the dialog text
    s = shlex.quote(s)
    return s.encode("ascii", "backslashreplace").decode()


def how_text(how):
    via, name = how.get("via"), how.get("name")
    if via == "stdin":
        return "stdin"
    if via not in ("env", "file") or not str(name).isidentifier():
        raise Fail("bad request: how")
    if via == "file":
        return f"a temporary file (${name})"
    return f"environment variable ${name}"


def dialog_text(path, how, argv, reason, who):
    """Rich text for the dialog; everything from the agent is escaped."""
    e = html.escape
    mark = "" if who["CALLER_SOURCE"] == "proc" else " (self-reported)"
    warning = who.get("WARNING")
    if warning:
        warning = f"<b style='color:#d00'>Warning: {e(warning)}</b><br>"
    scope = ("this session only" if who["SESSION_ID"]
             else "every caller without a session ID")
    return (
        f"<b>Use the password of</b> <tt>{e(q(path))}</tt><br>"
        f"<b>passed via:</b> {e(how)}<br><br>"
        "<b>to run:</b><pre style='white-space:pre-wrap'>"
        f"{e(' '.join(q(a) for a in argv))}</pre>"
        f"<b>in:</b> <tt>{e(q(who['CWD']))}</tt>{mark}<br>"
        f"<b>asked by:</b> {e(label(who))}{mark}<br>{warning or ''}<br>"
        f"<b>Why:</b><br>{e(reason).replace(chr(10), '<br>')}<br><br>"
        f"<i>Allow for {REMEMBER_HOURS} h: no more dialogs for this entry, "
        f"whatever the command, for {scope}.</i>"
    )


def dialog_timeout():
    # tests may shorten it; a timeout only ever denies
    try:
        return min(TIMEOUT, float(os.environ["AGENT_KP_DIALOG_TIMEOUT"]))
    except (KeyError, ValueError):
        return TIMEOUT


def client_gone(sock):
    gone = select.poll()
    gone.register(sock, select.POLLIN)  # the client never sends more: EOF
    return bool(gone.poll(0))


def ask(text, sock):
    """Show the dialog: (once|6h|deny|withdrawn|timed out|failed, detail)."""
    if client_gone(sock):
        return "withdrawn", ""
    try:
        proc = subprocess.Popen(
            [DIALOG, str(REMEMBER_HOURS)], stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, process_group=0)
    except OSError as e:
        return "failed", str(e)
    deadline = time.monotonic() + dialog_timeout()
    data = text.encode("utf-8", "backslashreplace")
    while True:
        try:
            out, err = proc.communicate(data, timeout=0.25)
            break
        except subprocess.TimeoutExpired:
            data = None
        left = client_gone(sock)
        if left or time.monotonic() > deadline:
            os.killpg(proc.pid, signal.SIGKILL)
            proc.communicate()
            return ("withdrawn" if left else "timed out"), ""
    answer = out.decode(errors="replace").rstrip("\n")
    if proc.returncode == 0 and out.count(b"\n") == 1 and answer in (
            "once", f"{REMEMBER_HOURS}h", "deny"):
        return answer, ""
    err = err.decode(errors="replace").strip().splitlines()
    return "failed", (err[-1] if err else f"exit status {proc.returncode}, printed {out[:40]!r}")[:200]


# Who is asking, from /proc of the connecting process where readable, else
# from what it says. Same uid as the agent, so it's for Jona's overview, not
# proof.
def caller(sock, req):
    creds = sock.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, struct.calcsize("3i"))
    pid, uid, _ = struct.unpack("3i", creds)
    if uid != os.getuid():
        raise Fail(f"uid {uid} may not use this service")
    try:
        cwd = os.readlink(f"/proc/{pid}/cwd")
        exe = os.readlink(f"/proc/{pid}/exe")
        env = proc_env(pid)
        source = "proc"
    except OSError:
        cwd, exe, env = req.get("cwd", ""), "", req.get("env", {})
        source = "self-reported"
    env = {k: str(env.get(k, "")) for k in CALLER_ENV}
    who = {
        "SESSION": session_title(env["CLAUDE_CODE_HOST_SESSION_ID"]),
        "SESSION_ID": env["CLAUDE_CODE_SESSION_ID"],
        "HOST_SESSION_ID": env["CLAUDE_CODE_HOST_SESSION_ID"],
        "AGENT": env["AI_AGENT"],
        "PARENTS": parents(pid),
        "CWD": str(cwd),
        "CALLER_SOURCE": source,
    }
    # the client runs on the same interpreter as this service
    if exe and exe != os.readlink("/proc/self/exe"):
        who["WARNING"] = f"not the agent-kp client: {q(exe)}"
    return who


def proc_env(pid):
    with open(f"/proc/{pid}/environ", "rb") as f:
        pairs = [v.split(b"=", 1) for v in f.read().split(b"\0") if b"=" in v]
    return {os.fsdecode(k): os.fsdecode(v) for k, v in pairs}


def session_title(host_id):
    # the Claude desktop app keeps one JSON per session, title included
    if not re.fullmatch(r"local_[0-9a-f-]+", host_id):
        return ""
    sessions = os.path.expanduser("~/.config/Claude/claude-code-sessions")
    for p in glob.glob(f"{sessions}/*/*/{host_id}.json"):
        try:
            with open(p) as f:
                return str(json.load(f)["title"])
        except (OSError, ValueError, KeyError, TypeError):
            pass
    return ""


def parents(pid, depth=6):
    """'agent-kp[14] < bash[12] < claude[10] < …': the caller and its parents."""
    chain = []
    while pid > 1 and len(chain) < depth:
        try:
            # the kernel cuts names at 15 bytes, maybe mid-character
            with open(f"/proc/{pid}/stat", errors="replace") as f:
                stat = f.read()
        except OSError:
            break
        # the name sits in parentheses and may contain spaces or ")" itself
        end = stat.rindex(")")
        chain.append(f"{stat[stat.index('(') + 1:end]}[{pid}]")
        pid = int(stat[end + 2:].split()[1])
    return " < ".join(chain)


def label(who):
    return who["SESSION"] or who["SESSION_ID"] or who["PARENTS"] or "unknown"


def utf8(s):
    # argv, env and paths may carry undecodable bytes (as surrogates), which
    # the journal binding refuses; log them as \xNN instead
    return s.encode("utf-8", "surrogateescape").decode("utf-8", "backslashreplace")


def audit(decision, who, path="", argv=(), exe="", how="", reason=""):
    """One journal entry per decision, before any password is fetched."""
    command = " ".join(q(a) for a in argv)
    lines = [f"{decision}: {path}" if path else decision]
    lines[0] += f", asked by {label(who)}"
    if who["CALLER_SOURCE"] != "proc":
        lines[0] += " (self-reported)"
    if who.get("WARNING"):
        lines.append(f"warning: {who['WARNING']}")
    if command:
        lines.append(command)
    if reason:
        lines.append(f"why: {reason}")
    fields = {
        "KP_DECISION": decision, "KP_ENTRY": path, "KP_COMMAND": command,
        "KP_EXE": exe, "KP_HOW": how, "KP_REASON": reason,
        **{f"KP_{k}": v for k, v in who.items()},
    }
    try:
        journal.send(utf8("\n".join(lines)), SYSLOG_IDENTIFIER="agent-kp",
                     **{k: utf8(v) for k, v in fields.items() if v})
    except (OSError, ValueError) as e:
        raise Fail(f"can't write the journal: {e}")


def uptime():
    # counts suspend and ignores clock changes
    return time.clock_gettime(time.CLOCK_BOOTTIME)


def hhmm(t):
    return time.strftime("%H:%M", time.localtime(time.time() + t - uptime()))


def recv_line(sock, limit=1 << 20):
    buf = b""
    while not buf.endswith(b"\n"):
        try:
            chunk = sock.recv(65536)
        except TimeoutError:
            raise Fail("bad message")
        if not chunk or len(buf) > limit:
            raise Fail("bad message")
        buf += chunk
    return buf


def run_request(req):
    """The run request's fields, if they have the right types."""
    argv = req.get("argv")
    vals = [req.get(k) for k in ("entry", "exe", "reason")]
    if not (argv and isinstance(argv, list) and isinstance(req.get("how"), dict)):
        raise Fail("bad request")
    if not all(isinstance(v, str) for v in vals + argv):
        raise Fail("bad request")
    return (*vals, argv, how_text(req["how"]))


class Service:
    """`agent-kp serve`: one D-Bus connection for the whole login, so
    KeePassXC's "Remember" sticks, and the 6 h approvals in memory."""

    def __init__(self, conn):
        self.conn = conn
        self.dbus_lock = threading.Lock()  # one connection, used by one at a time
        self.dialog_lock = threading.Lock()  # one dialog at a time, others wait
        # {(item path, session id): expiry in uptime()}; the D-Bus path names
        # the collection too, as UUIDs are only unique per database
        self.allowed = {}

    @contextlib.contextmanager
    def dbus(self):
        # a hung KeePassXC keeps its holder stuck; don't queue up behind it
        if not self.dbus_lock.acquire(timeout=TIMEOUT + 60):
            raise Fail("agent-kp service busy, KeePassXC isn't answering "
                       "(systemctl --user restart agent-kp)")
        try:
            yield self.conn
        finally:
            self.dbus_lock.release()

    def handle(self, sock):
        with sock:
            try:
                resp = self.dispatch(sock)
            except Fail as e:
                resp = {"ok": False, "code": e.code, "error": str(e)}
            except Exception as e:
                traceback.print_exc()
                resp = {"ok": False, "code": 2, "error": f"agent-kp service failed: {e!r}"}
            if resp:
                with contextlib.suppress(OSError):
                    sock.sendall(json.dumps(resp).encode() + b"\n")

    def dispatch(self, sock):
        sock.settimeout(10)  # a client that never sends doesn't keep a thread
        try:
            req = json.loads(recv_line(sock))
        except ValueError:
            raise Fail("bad request")
        sock.settimeout(None)
        if not isinstance(req, dict) or req.get("cmd") not in ("run", "forget"):
            raise Fail("bad request")
        who = caller(sock, req)
        if req["cmd"] == "forget":
            return self.forget(who)
        return self.run(req, who, sock)

    def forget(self, who):
        self.allowed.clear()
        audit("forgot all remembered entries", who)
        return {"ok": True}

    def remembered(self, key, log):
        until = self.allowed.get(key, 0)
        if until <= uptime():
            return None
        log(f"allowed, remembered until {hhmm(until)}")
        return f"allowed for this session until {hhmm(until)}, no dialog"

    def approve(self, key, text, sock, log):
        """A note for the agent once allowed, None if the client left."""
        note = self.remembered(key, log)
        if note:
            return note
        with self.dialog_lock:
            # it may have been allowed for this session while we waited
            note = self.remembered(key, log)
            if note:
                return note
            answer, detail = ask(text, sock)
            if answer == "once":
                log("allowed once")
                return ""
            if answer == f"{REMEMBER_HOURS}h":
                until = uptime() + REMEMBER_HOURS * 3600
                log(f"allowed for {REMEMBER_HOURS} h, until {hhmm(until)}")
                self.allowed[key] = until
                return f"allowed for this session until {hhmm(until)}"
            if answer == "withdrawn":
                log("withdrawn")
                return None
        if answer == "failed":
            log(f"dialog failed: {detail}")
            raise Fail(f"dialog failed: {detail}")
        if answer == "deny":
            log("denied")
            raise Fail("denied by user", 126)
        log("timed out")
        raise Fail("no answer, timed out", 126)

    def run(self, req, who, sock):
        entry, exe, reason, argv, how = run_request(req)
        with self.dbus() as conn:
            item, a = find_one(conn, entry)
        path = a["Path"]

        def log(decision):
            audit(decision, who, path, argv, exe, how, reason)

        text = dialog_text(path, how, [exe] + argv[1:], reason, who)
        note = self.approve((item.item_path, who["SESSION_ID"]), text, sock, log)
        if note is None:
            return None
        # it may have queued behind another dialog and been cancelled since
        if client_gone(sock):
            log("withdrawn")
            return None
        try:
            with self.dbus():
                secret = fetch(item)
        except (secretstorage.exceptions.PromptDismissedException,
                secretstorage.exceptions.LockedException):
            log("denied in KeePassXC")
            raise Fail("denied in KeePassXC", 126)
        except TimeoutError:
            log("no answer in KeePassXC, timed out")
            raise Fail("no answer in KeePassXC, timed out", 126)
        except secretstorage.exceptions.SecretServiceNotAvailableException:
            raise Fail(NO_SERVICE)
        if not secret:
            raise Fail(f"{path} has an empty password")
        return {"ok": True, "secret": base64.b64encode(secret).decode(), "note": note}


def serve(args):
    if args.socket:
        listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        os.umask(0o077)
        listener.bind(args.socket)
        listener.listen()
    else:
        fds = daemon.listen_fds()
        if len(fds) != 1:
            raise Fail("serve: expected one socket from systemd (or --socket PATH)")
        listener = socket.socket(fileno=fds[0])
    service = Service(secretstorage.dbus_init())
    while True:
        try:
            sock, _ = listener.accept()
        except OSError as e:  # e.g. out of fds; keep the 6 h memory
            print(f"agent-kp: accept: {e}", file=sys.stderr)
            time.sleep(1)
            continue
        threading.Thread(target=service.handle, args=(sock,), daemon=True).start()


def request(req):
    """Ask the service; its answer, or Fail with its error."""
    req["cwd"] = os.getcwd()
    req["env"] = {k: os.environ.get(k, "") for k in CALLER_ENV}
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        try:
            s.connect(socket_path())
        except OSError:
            raise Fail("agent-kp service not reachable "
                       "(systemctl --user status agent-kp.socket)")
        s.sendall(json.dumps(req).encode() + b"\n")
        try:
            resp = json.loads(recv_line(s))
        except (Fail, OSError, ValueError):
            raise Fail("the agent-kp service hung up "
                       "(journalctl --user -u agent-kp)")
    if resp.get("note"):
        print(f"agent-kp: {resp['note']}", file=sys.stderr)
    if not resp.get("ok"):
        raise Fail(resp.get("error"), resp.get("code", 2))
    return resp


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


def cmd_run(args):
    argv = args.command
    if argv and argv[0] == "--":
        argv = argv[1:]
    if not argv:
        raise Fail("run: no command given (put it after --)")
    prog = shutil.which(argv[0])
    if not prog:
        raise Fail(f"run: command not found: {argv[0]}")
    for var in (args.file, args.env):
        if var and not var.isidentifier():
            raise Fail(f"run: bad variable name {var}")
    via = "stdin" if args.stdin else "file" if args.file else "env"
    resp = request({
        "cmd": "run", "entry": args.entry, "argv": argv,
        "how": {"via": via, "name": args.file or args.env},
        "exe": os.path.realpath(prog), "reason": args.reason,
    })
    secret = base64.b64decode(resp["secret"])

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
            try:
                env[args.env] = secret.decode()
            except UnicodeDecodeError:  # its message would name a byte of it
                raise Fail("the password isn't UTF-8, use --stdin or --file") from None
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


def cmd_forget(args):
    request({"cmd": "forget"})


def main():
    p = argparse.ArgumentParser(
        prog="agent-kp",
        description="Use KeePassXC passwords without seeing them. Exit 126 "
        "means Jona denied or dismissed a prompt; 2 is an error, not a deny.")
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
    sub.add_parser("forget", help="drop all entries allowed for "
                   f"{REMEMBER_HOURS} h, so every run asks again")
    s = sub.add_parser("serve", help="the service behind run and forget "
                       "(systemd starts it)")
    s.add_argument("--socket", metavar="PATH",
                   help="listen on PATH instead of systemd's socket")
    args = p.parse_args()

    session_env()
    direct = {"search": cmd_search, "ls": cmd_ls, "info": cmd_info}
    try:
        if args.cmd in direct:
            with contextlib.closing(secretstorage.dbus_init()) as conn:
                rc = direct[args.cmd](conn, args)
        else:
            rc = {"run": cmd_run, "forget": cmd_forget,
                  "serve": serve}[args.cmd](args)
    except Fail as e:
        print(f"agent-kp: {e}", file=sys.stderr)
        rc = e.code
    sys.exit(rc or 0)


if __name__ == "__main__":
    main()

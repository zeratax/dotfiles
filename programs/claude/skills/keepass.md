---
name: keepass
description: Find entries in Jona's KeePassXC database and use their passwords in commands without ever seeing them. Use when a task needs a credential (API token, login, SSH/DB password, …) that lives in KeePass. Never ask Jona to paste a secret into the chat; use `agent-kp` instead.
---

# KeePass passwords via `agent-kp`

`agent-kp` talks to the running KeePassXC over the Secret Service D-Bus API.
**You never see a password, and you must keep it that way.**

- If the database is locked, KeePassXC asks Jona to unlock it (face auth or
  password, its own prompt).
- Each `run` shows Jona a dialog with the entry, the command and your reason.
  KeePassXC may then confirm the access in its own prompt as well.
- The password reaches the command via an env var, stdin or a 0600 tmpfs file,
  never argv. Anything the command prints has it replaced by `********`.

## Finding the entry

Searching and listing only read paths, usernames and URLs, never passwords, and
don't ask Jona anything (unless the DB is locked).

```bash
agent-kp search github          # path<TAB>username<TAB>URL of matching entries
agent-kp ls                     # all entry paths
agent-kp ls Work                # entries under /Work
agent-kp info "/Work/GitHub"    # Path, UserName, URL
```

`--entry` takes a full path (from `search`/`ls`), a title or a UUID. An
ambiguous title fails and lists the candidates.

## Using a password

```bash
# as an env var (default name: $SECRET)
agent-kp run --entry "/Work/GitHub" --env GH_TOKEN \
  --reason "List the open PRs on zeratax/dotfiles" -- gh pr list -R zeratax/dotfiles

# on stdin (password + newline)
agent-kp run --entry "/Servers/registry" --stdin \
  --reason "Log in to the registry to push the archive-browser image" -- \
  docker login -u jona --password-stdin registry.example

# as a file; $NAME holds the path, deleted afterwards
agent-kp run --entry "/Servers/db" --file PGPASSFILE --reason "…" -- psql -h db …
```

The variable only exists inside the command. To use it in an argument, let a
shell expand it there, in single quotes so your own shell doesn't:
`-- sh -c 'curl -fsS -H "Authorization: Bearer $SECRET" https://…'`.

Only the entry's **Password** field is available. Protected custom attributes
are not exposed over Secret Service. Ask Jona if you need one.

## Rules

- **Run every `run` call with `run_in_background: true`** (it waits for Jona's
  approval), and `search`/`ls`/`info` too if the DB may be locked. Tell him a
  dialog is waiting. Don't poll; you'll be notified.
- **Never make the password visible**: no `echo $SECRET`, `env`, `printenv`,
  `set -x`, `cat $FILE`, verbose/debug flags that dump headers, and no writing
  it into files that outlive the command. Masking is a safety net, not
  permission. It misses encoded forms (base64, URL-encoded, hashed) and short
  passwords.
- **Never put the password into argv** (`--password=$SECRET` expanded by your
  own shell): argv is world-readable in `/proc`. Expanding it inside
  `sh -c '…'` is fine when the tool has no env/stdin/file option.
- Don't use `secret-tool`, `keepassxc-cli` or raw D-Bus calls to read
  passwords. They would print them into your context.
- **The reason is for Jona**: what the command does with the password. Exit
  126 = denied or dismissed. Don't retry; ask.
- `agent-kp` only reads. To add or change entries, ask Jona.
- Needs KeePassXC running with Secret Service enabled. If it says "no Secret
  Service" or "no collections", tell Jona.

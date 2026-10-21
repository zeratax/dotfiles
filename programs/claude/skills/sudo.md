---
name: sudo
description: Run a command as root on this machine. Plain sudo/pkexec fail in agent sessions (NoNewPrivs); use `agent-sudo`, which shows Jona the command plus your reason in a dialog, lets him approve or deny, and authenticates via polkit. Use whenever a task needs root (nixos-rebuild switch, systemctl on system units, editing /etc, reading root-only logs, …).
---

# Root commands via `agent-sudo`

`sudo` and `pkexec` don't work from an agent shell: the agent process runs with
`NoNewPrivs=1`, so setuid is ignored. `agent-sudo` gets around that the approved
way:

1. A KDE dialog shows Jona the **exact command** (with the program resolved to an
   absolute path), the working directory and **your reason**. He clicks *Run as
   root* or *Deny*.
2. On *Run*, polkit asks for his password (or face auth) in its own dialog. The
   password never goes through you or the script.

```bash
agent-sudo --reason "Activate the nixos-config change that enables X" -- \
  nixos-rebuild switch --flake ~/Projects/nixos-config#surface
```

## Rules

- **Always run it with `run_in_background: true`.** It blocks until Jona
  reacts, which can take minutes. You'll be notified when it exits; don't poll.
  Tell him in your reply that a dialog is waiting.
- **One command per request, as specific as possible.** No `bash -c '…'`
  wrappers that hide what runs, and no `sh`/`env`/interpreter used to smuggle
  in a second command. If you really need a pipeline as root, say so in the
  reason and keep the script short and readable in the dialog.
- **The reason is for Jona.** One or two plain sentences: what this does and
  why it needs root. Don't oversell or downplay it.
- **Exit 126 = denied** (in the dialog or by dismissing the polkit prompt),
  **127 = polkit authentication failed**. Don't retry the same request. Ask
  Jona what he wants instead.
- Use programs from the system or the nix store. Anything else (e.g.
  `~/.local/bin`) gets a red warning in the dialog, because it could be swapped
  between approval and execution.
- Root gets a fixed `PATH` (`/run/wrappers/bin:/run/current-system/sw/bin`).
  For anything else, pass an absolute path (e.g. `~/.nix-profile/bin/foo`).
- stdin, stdout and stderr are passed through and the command's exit code is
  returned. The cwd is kept.
- Prefer `nixos-rebuild switch --flake ~/Projects/nixos-config#surface` over
  `nh os switch` (nh calls sudo internally). Build first without root
  (`nh os build ~/Projects/nixos-config`) so the switch itself is quick.
- Every request (approved, denied, exit code) is logged to
  `~/.local/state/agent-sudo.log`.

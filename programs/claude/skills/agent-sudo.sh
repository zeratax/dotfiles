# agent-sudo: run one command as root on behalf of an agent, with Jona in the loop.
#
# 1. A KDE dialog shows the exact command, the working directory and the agent's
#    reason; Jona clicks Run or Deny.
# 2. On Run, pkexec asks polkit, so KDE's own password dialog (or face auth)
#    authenticates. The password never passes through this script or the agent.
#
# pkexec is started through the user systemd manager: agent processes (Claude
# Code / Claude Desktop) run with NoNewPrivs=1, which every child inherits and
# which makes setuid binaries useless. The user manager doesn't have it.

usage() {
  cat <<'EOF'
usage: agent-sudo --reason "<why>" [--] <command> [args...]

Asks Jona (GUI dialog) to approve running <command> as root, then runs it via
pkexec (polkit password / face auth). stdin/stdout/stderr are passed through.

exit codes: the command's own; 126 if Jona denied or dismissed a dialog,
127 if polkit authentication failed.
EOF
}

die() {
  echo "agent-sudo: $*" >&2
  exit 2
}

html_escape() {
  local s=$1
  s=${s//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  s=${s//$'\n'/<br>}
  printf '%s' "$s"
}

reason=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -r | --reason)
      [[ $# -ge 2 ]] || die "--reason needs an argument"
      reason=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*) die "unknown option $1 (see --help)" ;;
    *) break ;;
  esac
done
[[ -n $reason ]] || die "--reason is required: say why this needs root"
[[ $# -gt 0 ]] || die "no command given"

# root gets a fixed system PATH, never the agent's (which has user-writable dirs)
root_path=/run/wrappers/bin:/run/current-system/sw/bin

# resolve the program up front so the dialog shows exactly what runs
# (type -P: only files, never builtins/functions that would resolve to ./name)
prog=$1
shift
if [[ $prog != */* ]]; then
  resolved=$(PATH=$root_path type -P -- "$prog" || type -P -- "$prog" || true)
  [[ -n $resolved ]] || die "command not found: $prog"
  prog=$resolved
fi
[[ -f $prog && -x $prog ]] || die "not executable: $prog"
# run the symlink itself (multi-call binaries like coreutils dispatch on argv[0])
# but show its target. Anything outside the immutable store could be swapped
# after approval, so flag it
prog=$(realpath -s -- "$prog")
target=$(realpath -- "$prog")
warning=""
[[ $target == /nix/store/* ]] || warning="<p style='color:#d33'><b>Warning:</b> this program is not in /nix/store and could be changed between approval and execution.</p>"
[[ $target == "$prog" ]] || warning="<tt>→ $(html_escape "$(LC_ALL=C printf '%q' "$target")")</tt><br>$warning"

# agents' shells don't inherit the graphical session; point at it
uid=$(id -u)
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$uid}
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}
export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-wayland}

# LC_ALL=C: %q then escapes non-ASCII too, so bidi overrides or zero-width
# characters can't disguise the command in the dialog
cmdline=$(LC_ALL=C printf '%q ' "$prog" "$@")
cwd=$(LC_ALL=C printf '%q' "$PWD")
log=${XDG_STATE_HOME:-$HOME/.local/state}/agent-sudo.log
mkdir -p "$(dirname "$log")"
logline() { printf '%s\t%s\t%s\t%s\t%s\n' "$(date -Is)" "$1" "$cwd" "$cmdline" "${reason//$'\n'/ }" >>"$log"; }

# forced rich text with everything escaped: the agent must not be able to hide
# part of the command with markup
text="<html><b>Run as root:</b><br><pre style='white-space:pre-wrap'>$(html_escape "$cmdline")</pre>$warning"
text+="<b>in:</b> <tt>$(html_escape "$cwd")</tt><br><br>"
text+="<b>Why:</b><br>$(html_escape "$reason")</html>"

if ! kdialog --title "Agent requests root" --warningyesno "$text" \
  --yes-label "Run as root" --no-label "Deny" 2>/dev/null; then
  logline denied
  echo "agent-sudo: denied by user" >&2
  exit 126
fi
logline approved

set +e
/run/current-system/sw/bin/systemd-run --user --pipe --wait --quiet --collect --same-dir \
  /run/wrappers/bin/pkexec --keep-cwd /run/current-system/sw/bin/env PATH="$root_path" "$prog" "$@"
rc=$?
set -e
logline "exit=$rc"
exit "$rc"

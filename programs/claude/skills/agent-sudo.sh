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
#
# The paths below are filled in by sudo.nix, for NixOS or for a generic Linux
# host like kaine (CachyOS). On the generic hosts the Claude desktop app runs
# agents in a buildFHSEnv container that hides the host's /usr (pacman, pkexec,
# …), so this script re-runs itself from the user systemd manager, outside the
# container, before it resolves and shows the command.
#
# systemd-run is always called with --expand-environment=no: by default it
# expands $VAR in the arguments, so root could run something other than what
# the dialog showed.
#
# root gets a fixed system PATH, never the agent's (which has user-writable dirs)
root_path=@rootPath@
pkexec=@pkexec@
systemd_run=@systemdRun@
env_bin=@env@
# the program shown gets a red warning unless both its directory and its final
# target are under one of these (root-owned, package-managed)
trusted_prefixes=(@trustedPrefixes@)

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

# Decided by what this process can see, not by a variable the caller controls:
# pkexec missing means we're inside the container, so re-run on the host
if [[ ! -x $pkexec ]]; then
  [[ -z ${AGENT_SUDO_ON_HOST:-} ]] || die "$pkexec not found, even outside the container"
  self=$(realpath -- "$0")
  setenv=(--setenv=AGENT_SUDO_ON_HOST=1 --setenv=PATH="$PATH")
  if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
    setenv+=(--setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY")
  fi
  # if the agent's call is killed, take the host side down with it, so a later
  # click can't run a command nobody is watching: TERM the inner pkexec unit
  # (withdraws a pending polkit prompt; once the command runs as root the
  # signal is refused, and kill rather than stop never escalates to SIGKILL
  # mid-transaction), then stop the outer unit (and a pending dialog).
  # Backgrounded + wait, because bash defers traps until a foreground child exits
  unit=agent-sudo-$$-$RANDOM
  setenv+=(--setenv=AGENT_SUDO_UNIT="$unit")
  # shellcheck disable=SC2329 # called from the traps below
  stop_host() {
    local systemctl=${systemd_run%/*}/systemctl
    "$systemctl" --user kill --signal=TERM "$unit-root.service" 2>/dev/null
    "$systemctl" --user stop "$unit.service" 2>/dev/null
    exit "$1"
  }
  trap 'stop_host 129' HUP
  trap 'stop_host 130' INT
  trap 'stop_host 143' TERM
  # <&0: a background job's stdin would otherwise be /dev/null
  "$systemd_run" --user --pipe --wait --quiet --collect --same-dir \
    --expand-environment=no --unit="$unit" "${setenv[@]}" \
    "$self" --reason "$reason" -- "$@" <&0 &
  set +e
  wait "$!"
  rc=$?
  set -e
  exit "$rc"
fi

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
# but show its target. Pin the directory, though: a user-owned symlink or
# directory on the way could be re-pointed after approval
prog=$(realpath -s -- "$prog")
dir=$(realpath -- "$(dirname -- "$prog")")
prog=$dir/${prog##*/}
target=$(realpath -- "$prog")
is_trusted() {
  local p
  for p in "${trusted_prefixes[@]}"; do
    if [[ $1 == "$p"* ]]; then return 0; fi
  done
  return 1
}
warning=""
if ! is_trusted "$dir/" || ! is_trusted "$target"; then
  warning="<p style='color:#d33'><b>Warning:</b> this program is outside $(html_escape "${trusted_prefixes[*]}") and could be changed between approval and execution.</p>"
fi
[[ $target == "$prog" ]] || warning="<tt>→ $(html_escape "$(LC_ALL=C printf '%q' "$target")")</tt><br>$warning"

# agents' shells don't inherit the graphical session; point at it
uid=$(id -u)
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$uid}
if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
  # not always wayland-0 (kaine's session is on wayland-1)
  for s in "$XDG_RUNTIME_DIR"/wayland-[0-9]; do
    if [[ -S $s ]]; then
      WAYLAND_DISPLAY=${s##*/}
      break
    fi
  done
fi
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
"$systemd_run" --user --pipe --wait --quiet --collect --same-dir --expand-environment=no \
  --unit="${AGENT_SUDO_UNIT:-agent-sudo-$$}-root" \
  "$pkexec" --keep-cwd "$env_bin" PATH="$root_path" "$prog" "$@"
rc=$?
set -e
logline "exit=$rc"
exit "$rc"

# cc-login HOST SESSION [PANE]
#
# Finish a `claude` /login that's waiting in a zellij session on another machine.
# Copying the login URL out over ssh breaks it at the terminal width, so this
# grabs the pane, rejoins the URL, opens it here, then sends the code you get
# back into the pane.

if [ $# -lt 2 ]; then
  echo "usage: cc-login HOST SESSION [PANE]   e.g. cc-login nas archive-browser" >&2
  exit 2
fi
host=$1
session=$2
pane=${3:-}

# Runs a script with bash on HOST. Values are baked into the script text rather
# than passed as ssh arguments, which the remote login shell (fish on kaine)
# would parse again.
on_host() {
  local vars=$1 body=$2
  # The session's own zellij binary: the client has to match the server version.
  # shellcheck disable=SC2016
  local find_zellij='
z=$(pgrep -a zellij | awk -v s="/$session" '"'"'$3 == "--server" && substr($4, length($4) - length(s) + 1) == s { print $2; exit }'"'"')
[ -n "$z" ] || { echo "no zellij session \"$session\"" >&2; exit 1; }
'
  ssh "$host" bash -s <<<"$vars$find_zellij$body"
}

# Dump PANE, or every pane until one shows a login URL. The first line says
# which pane it was.
# shellcheck disable=SC2016
dump=$(on_host "$(printf 'session=%q pane=%q\n' "$session" "$pane")" '
if [ -n "$pane" ]; then
  echo "terminal_${pane#terminal_}"
  timeout 10 "$z" --session "$session" action dump-screen --pane-id "$pane" </dev/null
  exit
fi
for i in $(seq 0 40); do
  out=$(timeout 10 "$z" --session "$session" action dump-screen --pane-id "terminal_$i" </dev/null) || continue
  case $out in *oauth/authorize*) echo "terminal_$i"; printf "%s\n" "$out"; exit ;; esac
done
echo "no pane in \"$session\" shows a login URL" >&2
exit 1
')
pane=$(head -n1 <<<"$dump")

# The URL starts at the beginning of a line and runs until the next blank one.
url=$(tail -n +2 <<<"$dump" | awk '
  /^[[:space:]]*https:\/\/[^ ]*oauth\/authorize/ { f = 1 }
  f && /^[[:space:]]*$/ { exit }
  f { gsub(/[[:space:]]/, ""); printf "%s", $0 }
')
if [ -z "$url" ]; then
  echo "no login URL in $pane on $host:$session. Is /login waiting there?" >&2
  exit 1
fi

echo "$url"
echo
if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
  xdg-open "$url" >/dev/null 2>&1 &
  echo "Opened in your browser. Approve it there."
else
  echo "Open that URL in a browser and approve it."
fi

read -r -p "Paste the code here: " code
[ -n "$code" ] || exit 1

# shellcheck disable=SC2016
on_host "$(printf 'session=%q pane=%q code=%q\n' "$session" "$pane" "$code")" '
timeout 10 "$z" --session "$session" action write-chars --pane-id "$pane" "$code" </dev/null
timeout 10 "$z" --session "$session" action write --pane-id "$pane" 13 </dev/null
'
echo "Sent the code to $pane on $host:$session."

file="$(readlink -f $1)"
url=$2
output=$(curl -F"file=@${file}" $url)
echo -n $output | xclip -selection primary
echo -n $output | xclip -selection clipboard
notify-send "Uploaded" "$(xclip -selection clipboard -out)"


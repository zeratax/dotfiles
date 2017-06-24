status="uploaded"
file=$(filename=$(date +%Y-%m-%d)_scrot.png ; maim $filename -s; echo -n $filename)
url="https://uguu.se/api.php?d=upload-tool"
if [ ! -f $file ]; then
    echo "Screenshot aboarted"
else
  output=$(curl -F"file=@${file}" $url)
  echo -n $output | xclip -selection primary
  echo -n $output | xclip -selection clipboard
  notify-send "Screenshot uploaded" "$(xclip -selection clipboard -out)"
  rm "${file}"
fi


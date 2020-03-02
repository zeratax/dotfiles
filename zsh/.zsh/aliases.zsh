# alias screenrecord="ffmpeg -f pulse -ac 2 -i 0 -f x11grab -r 30 -s 1920x1080 -i :0.0 -acodec pcm_s16le -vcodec libx264 -preset ultrafast -crf 0 -threads 0 "screen_$(date -u +"%Y-%m-%dT%H:%M:%SZ").mp4""
# alias screenshot="maim -s > "$HOME/Pictures/screenshots/screen_$(date -u +"%Y-%m-%dT%H:%M:%SZ").png""

alias ls='ls --color=auto'
alias rot13="tr '[A-Za-z]' '[N-ZA-Mn-za-m]'"
alias killWindow="xprop _NET_WM_PID | cut -d' ' -f3"

# upload() {
#   if [ $# -eq 0 ]; then echo "No arguments specified. "; return 1; fi
#   scp "$1" "zera.tax:/usr/share/nginx/html/files/$1"; echo "https://zera.tax/f/$1";
# }
#
function swap()
{
    local TMPFILE=tmp.$$
    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

function url_encode() {
    local _length="${#1}"
    for (( _offset = 0 ; _offset < _length ; _offset++ )); do
        _print_offset="${1:_offset:1}"
        case "${_print_offset}" in
            [a-zA-Z0-9.~_-]) printf "${_print_offset}" ;;
            ' ') printf + ;;
            *) printf '%%%X' "'${_print_offset}" ;;
        esac
    done
}

function screenshot() {
  filename="screen_$(date -u +"%Y-%m-%dT%H:%M:%SZ").png"
  maim -s > "$HOME/Pictures/screenshots/$filename"
}

function screenrecord() {
  filename="screen_$(date -u +"%Y-%m-%dT%H:%M:%SZ").mkv"
  ffmpeg -f pulse -ac 2 -i 0 -f x11grab -r 30 -s 1920x1080 -i :0.0 -acodec pcm_s16le -vcodec libx264 -preset ultrafast -crf 0 -threads 0 "$HOME/Videos/screenrecords/$filename"
}

function 0x0() {
    if [ $# -eq 0 ]; then echo "No arguments specified. "; return 1; fi
    curl -F"file=@$1" https://0x0.st;
}

function svg2pdf() { if [ $# -eq 0 ]; then echo "No arguments specified. "; return 1; fi
  filename=$(basename "$1")
  filename="${filename%.*}"
  inkscape -D -z --file=$filename.svg --export-pdf=$filename.pdf --export-latex;
}

function transfer() {
    if [ $# -eq 0 ]; then echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi
    tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile;
}

# source https://github.com/xero/dotfiles/blob/master/zsh/.zsh/aliases.zsh

# read markdown files like manpages
function md() {
    pandoc -s -f markdown -t man "$*" | man -l -
}

# nullpointer url shortener
function short() {
  curl -F"shorten=$*" https://0x0.st
}

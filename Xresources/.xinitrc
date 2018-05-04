#! /bin/bash
export WALLPAPER_DIR=~/Bilder/Photography/Masashi\ Wakui/* 
[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources
#eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
#export GNOME_KEYRING_PID
#export GNOME_KEYRING_SOCKET
keychain -quiet -agents gpg
export SSH_AUTH_SOCK

# alsactl init &

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
	for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
		[ -x "$f" ] && . "$f"
	done
	unset f
fi

#xscreensaver &
xsetroot -cursor_name left_ptr &

case "$1" in
	i3)
		feh --randomize --bg-fill $WALLPAPER_DIR &
		compton --config ~/.compton.config -b &
		exec i3
	;;
	cinnamon)
		exec cinnamon-session
	;;
	budgie)
		export XDG_CURRENT_DESKTOP=Budgie:Gnome &
		exec budgie-desktop
	;;
esac

# source: https://github.com/xero/dotfiles/blob/master/zsh/.zsh/security.zsh

alias checkrootkits="sudo rkhunter --update; sudo rkhunter --propupd; sudo rkhunter --check"
alias checkvirus="clamscan --recursive=yes --infected /home"
alias updateantivirus="sudo freshclam"
# source: https://github.com/xero/dotfiles/blob/master/zsh/.zsh/nodejs.zsh

#node version manager
source ~/.nvm/nvm.sh

# aliases
alias node="sudo node"
alias npm="sudo npm"
alias npminstall="sudo rm -rf node_modules && sudo npm cache clear && sudo npm cache clean && npm install"
# alias npminstall="sudo rm -rf node_modules && sudo npm cache clear && sudo npm cache clean && sudo PYTHON=/usr/bin/python2 npm install"
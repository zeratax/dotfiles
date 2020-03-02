export CUDA_PATH=/opt/cuda
export RUBY_PATH=$(ruby -e 'puts Gem.user_dir')
export PATH=$HOME/bin:/usr/local/bin:$RUBY_PATH/bin:$CUDA_PATH/bin:$CUDA_PATH/nsight-compute-2019.4.0:$PATH

#export MANPATH=/usr/local/man:$MANPATH

#preferred editor for local and remote sessions
export EDITOR=vim
export VISUAL=vim

export LD_LIBRARY_PATH=$CUDA_PATH/lib64:$CUDA_PATH/targets/x86_64-linux/include/:$LD_LIBRARY_PATH

#emoji-cli
#export EMOJI_CLI_KEYBIND=^e
# added by travis gem
[ -f /home/motoko/.travis/travis.sh ] && source /home/motoko/.travis/travis.sh

if [ -d "$HOME/adb-fastboot/platform-tools" ] ; then
 export PATH="$HOME/adb-fastboot/platform-tools:$PATH"
fi

[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh


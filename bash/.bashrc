# Environments
export $PAGER less
export TERM=xterm-color
export HISTSIZE=-1
export HISTFILESIZE=-1

# All aliases must be defined in .bash_aliases
if [ -e $HOME/.bash_aliases ]; then
  source $HOME/.bash_aliases
fi

# Add own scripts
if [ -e  $HOME/.local/bin ]; then
  export PATH="$PATH:$HOME/.local/bin"
fi

if [ -e  $HOME/local/bin ]; then
  export PATH="$PATH:$HOME/local/bin"
fi

if [ -e  $HOME/bin ]; then
  export PATH="$PATH:$HOME/bin"
fi

if [ -e  $HOME/rtags/bin ]; then
   export PATH="$PATH:$HOME/rtags/bin"
fi

# Add own functions
if [ -e $HOME/.bash_functions ]; then
  source $HOME/.bash_functions
fi

# Set the bash prompt PS1
if [ -e $HOME/.bash_prompt ]; then
  source $HOME/.bash_prompt
fi

# Load some user defined constants
if [ -e $HOME/.bash_constants ]; then
  source $HOME/.bash_constants
fi

if [ -e $HOME/.bash_work ]; then
  source $HOME/.bash_work
fi


if [ -e $HOME/.bash_zellij ]; then
  source $HOME/.bash_zellij
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

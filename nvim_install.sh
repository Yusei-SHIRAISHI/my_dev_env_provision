#! /bin/bash

set -eu

if   [ -e /etc/debian_version ] ||
     [ -e /etc/debian_release ]; then
  # Check Ubuntu or Debian
  if [ -e /etc/lsb-release ]; then
    # Ubuntu
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
  else
    # Debian
    echo "Not supported"
    exit 1
  fi
elif [ -e /etc/arch-release ]; then
  # Arch Linux
  echo "Not supported"
  exit 1
else
  echo "Not supported"
  exit 1
fi

if [ ! -e ~/.my_dotfiles ]; then
  git clone https://github.com/yusei-shiraishi/my_dotfiles.git ~/.my_dotfiles
fi

#mkdir -p ~/.config/nvim
#ln -sfn ~/.my_dotfiles/.vimrc ~/.config/nvim/init.vim
#mkdir -p ~/.cache/tmp
#
## vim-plug
#sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
#       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
#vim +'PlugInstall --sync' +qa

if [ -e ~/.zsh.d ]; then
  echo 'export PATH=$PATH:/opt/nvim-linux64/bin' > ~/.zsh.d/nvim
  echo 'alias vim="nvim"' >> ~/.zsh.d/alias
fi

rm ./nvim-linux64*

echo "complete!!"
vim --version

exit 0

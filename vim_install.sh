#! /bin/bash

set -eu

if   [ -e /etc/debian_version ] ||
     [ -e /etc/debian_release ]; then
  # Check Ubuntu or Debian
  if [ -e /etc/lsb-release ]; then
    # Ubuntu
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y vim
    #yes Y | sudo apt install build-essential libcurl6-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev
  else
    # Debian
    echo "Not supported"
    exit 1
  fi
elif [ -e /etc/arch-release ]; then
  # Arch Linux
  yes Y | sudo pacman -Syu
  yes Y | sudo pacman -S core/make core/autoconf core/gcc
else
  echo "Not supported"
  exit 1
fi

## Custom Build
#DIR=vim
#
#git clone https://github.com/vim/vim.git
#
#pushd ${DIR}
#
#./configure --with-features=normal --without-x --enable-gui=auto --disable-smack --disable-selinux --disable-netbeans --disable-arabic --disable-farsi --enable-terminal --enable-multibyte --enable-fontset --disable-canberra --disable-gpm --disable-sysmouse
#make
#sudo make install
#
#popd

if [ -e ~/.myDotfiles ]; then
  git clone https://github.com/yusei-shiraishi/myDotfiles.git ~/.my_dotfiles
fi
ln -s ~/.my_dotfiles/.vimrc ~/
mkdir -p ~/.cache/tmp

# vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +'PlugInstall --sync' +qa

echo "complete!!"
vim --version

exit 0

#! /bin/bash

set -eu

if   [ -e /etc/debian_version ] ||
     [ -e /etc/debian_release ]; then
  # Check Ubuntu or Debian
  if [ -e /etc/lsb-release ]; then
    # Ubuntu
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y zsh
  else
    # Debian
    echo "Not supported"
    exit 1
  fi
elif [ -e /etc/arch-release ]; then
  # Arch Linux
  yes Y | sudo pacman -Syu
  yes Y | sudo pacman -S core/make core/gcc core/which
else
  echo "Not supported"
  exit 1
fi

## Custom Install
#VERSION=5.8
#SRC_DIR=zsh-${VERSION}
#TAR_XZ=${SRC_DIR}.tar.xz
#
#curl -L -o ${TAR_XZ} https://sourceforge.net/projects/zsh/files/zsh/${VERSION}/zsh-${VERSION}.tar.xz/download
#tar -Jxvf ${TAR_XZ}
#
#pushd ${SRC_DIR}
#
#./configure
#make
#sudo make install
#
#popd
#
#rm -rf ${SRC_DIR} ${TAR_GZ}

sudo sh -c "echo \"$(which zsh)\" >> /etc/shells"
sudo chsh -s $(which zsh) $(whoami)

if [ -e ~/.myDotfiles ]; then
  git clone https://github.com/yusei-shiraishi/my_dotfiles.git ~/.my_dotfiles
fi
mkdir ~/.zsh.d
ln -sfn ~/.my_dotfiles/.zshrc ~/

echo "complete!!"
exit 0

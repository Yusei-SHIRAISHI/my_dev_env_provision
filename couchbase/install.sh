#! /bin/bash

set -eu

if   [ -e /etc/debian_version ] ||
     [ -e /etc/debian_release ]; then
  # Check Ubuntu or Debian
  if [ -e /etc/lsb-release ]; then
    # Ubuntu
    sudo apt update
    sudo apt upgrade
    yes Y | sudo apt install build-essential libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev autoconf
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

VERSION=2.31.1
SRC_DIR=git-${VERSION}
TAR_GZ=${SRC_DIR}.tar.gz

curl -L -o ${TAR_GZ} https://github.com/git/git/archive/refs/tags/v${VERSION}.tar.gz
tar -xzvf ${TAR_GZ}

pushd ${SRC_DIR}

make configure
./configure --prefix=/usr/local
make
sudo make install

popd

rm -rf ${SRC_DIR} ${TAR_GZ}

if [ -e ~/.myDotfiles ]; then
  git clone https://github.com/yusei-shiraishi/myDotfiles.git ~/.my_dotfiles
fi
ln -s ./.my_dotfiles/.gitconfig ./

echo "complete!!"
git --version

exit 0

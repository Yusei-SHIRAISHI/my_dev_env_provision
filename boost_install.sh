#! /bin/bash

set -eu

if   [ -e /etc/debian_version ] ||
     [ -e /etc/debian_release ]; then
  # Check Ubuntu or Debian
  if [ -e /etc/lsb-release ]; then
    # Ubuntu
    sudo apt update
    sudo apt upgrade
    sudo apt install build-essential
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

VERSION=1.76.0
SRC_DIR=boost_1_76_0
TAR_GZ=${SRC_DIR}.tar.gz

curl -L -o ${TAR_GZ} https://boostorg.jfrog.io/artifactory/main/release/${VERSION}/source/${TAR_GZ}
tar -xzvf ${TAR_GZ}

pushd ${SRC_DIR}

./bootstrap.sh --prefix=/usr/local
sudo ./b2 link=static,shared threading=multi variant=release install -j2

popd

rm -rf ${SRC_DIR} ${TAR_GZ}

echo "complete!!"
exit 0

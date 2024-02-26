#! /bin/bash

set -eu

type git
if [ $? != 0 ]; then
  echo "git does not exists. Please install git."
fi

type zsh
if [ $? != 0 ]; then
  echo "zsh does not exists. Please install zsh."
fi

git clone https://github.com/anyenv/anyenv ~/.anyenv

if [ ! -e ~/.zsh.d/anyenv ]; then
  echo 'export PATH=$PATH:$HOME/.anyenv/bin' >> ~/.zsh.d/anyenv
  echo 'eval "$(anyenv init - zsh)"' >> ~/.zsh.d/anyenv
fi

mkdir -p $HOME/.anyenv/plugins
git clone https://github.com/znz/anyenv-update.git $HOME/.anyenv/plugins/anyenv-update

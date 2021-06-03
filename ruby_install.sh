#! /bin/bash

set -eu

IPATH=~/.rbenv

git clone https://github.com/rbenv/rbenv.git $IPATH
mkdir -p $IPATH/plugins
git clone https://github.com/rbenv/ruby-build.git $IPATH/plugins/ruby-build

echo "complete!!"

exit 0

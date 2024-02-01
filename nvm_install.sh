#! /bin/bash

set -eu

VERSION=v0.39.7

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${VERSION}/install.sh | bash

echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}"  ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh"  ] && \. "$NVM_DIR/nvm.sh" ' >> ~/.zsh.d/nvm

echo "complete!!"

exit 0

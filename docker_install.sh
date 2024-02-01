#! /bin/bash

set -eu

if   [ -e /etc/debian_version ] ||
     [ -e /etc/debian_release ]; then
  # Check Ubuntu or Debian
  if [ -e /etc/lsb-release ]; then
    # Ubuntu
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y ca-certificates curl gnupg lsb-release

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update

    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    # Debian
    echo "Not supported"
    exit 1
  fi
else
  echo "Not supported"
  exit 1
fi

# docker-compose
curl -L https://github.com/docker/compose/releases/download/1.6.2/run.sh > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

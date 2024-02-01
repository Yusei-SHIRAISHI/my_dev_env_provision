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

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
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

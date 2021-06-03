#! /bin/bash

set -e

# install depend
apt-get update
apt-get install -y wget git libxml2-dev libssl-dev pkg-config zlib1g-dev libbz2-dev libjpeg-dev libpng-dev build-essential libcurl4-gnutls-dev libicu-dev libmcrypt-dev libreadline-dev libtidy-dev libxslt1-dev autoconf

#
# phpenv install
#
git clone git://github.com/phpenv/phpenv.git ~/.phpenv
git clone git://github.com/php-build/php-build.git ~/.phpenv/plugins/php-build
echo 'export PATH="$HOME/.phpenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(phpenv init -)"' >> ~/.bashrc
source ~/.bashrc

#
# php install
#
PHP_VERSION=7.0.0
phpenv install ${PHP_VERSION}
useradd -s/sbin/nologin -M wordpress || echo 'user exist'
ln ~/.phpenv/versions/${PHP_VERSION}/sbin/php-fpm ~/.phpenv/versions/${PHP_VERSION}/bin/php-fpm
phpenv global ${PHP_VERSION}
phpenv rehash

#
# wordpress install
#
current=$(cd $(dirname $0) && pwd)

WORDPRESS_VERSION=5.4.1
wordpress_tarball=${WORDPRESS_VERSION}-ja.tar.gz
wordpress_archivedir=wordpress

# purge depend
apt-get purge -y wget git libxml2-dev libssl-dev pkg-config zlib1g-dev libbz2-dev libjpeg-dev libpng-dev build-essential libcurl4-gnutls-dev libicu-dev libmcrypt-dev libreadline-dev libtidy-dev libxslt1-dev autoconf

exit 0

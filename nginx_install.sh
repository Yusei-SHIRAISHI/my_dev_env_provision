#! /bin/sh

set -e

# install depend
apt-get update
apt-get install -y wget make build-essential libpcre3-dev zlib1g-dev libgd-dev

#
# openssl download
#

current=$(cd $(dirname $0) && pwd)

openssl_version=1.1.1g
openssl_tarball=openssl-${openssl_version}.tar.gz
openssl_archivedir=openssl-${openssl_version}

cd ${current}

wget http://www.openssl.org/source/${openssl_tarball}
tar zxvf ${openssl_tarball}

#
# install nginx
#

nginx_version=1.17.10
nginx_tarball=nginx-${nginx_version}.tar.gz
nginx_archivedir=nginx-${nginx_version}
prefix=/usr/local/nginx

wget http://nginx.org/download/${nginx_tarball}
tar xzvf ${nginx_tarball}

useradd -s/sbin/nologin -d/usr/local/nginx -M nginx || echo 'user exist'

# modules
## headers_more
headers_more_version=0.33
headers_more_tarball="v${headers_more_version}.tar.gz"
headers_more_archivedir="headers-more-nginx-module-${headers_more_version}"
wget https://github.com/openresty/headers-more-nginx-module/archive/${headers_more_tarball}
tar xzvf ${headers_more_tarball}

cd ${nginx_archivedir}

./configure \
  --prefix=${prefix} \
  --without-mail_pop3_module \
  --without-mail_imap_module \
  --without-mail_smtp_module \
  --with-file-aio \
  --with-ipv6 \
  --with-pcre \
  --with-http_ssl_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_image_filter_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gzip_static_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_degradation_module \
  --with-http_stub_status_module \
  --with-debug \
  --add-module=${current}/${headers_more_archivedir} \
  --with-openssl=${current}/${openssl_archivedir} \
  --group=nginx \
  --user=nginx;

make && make install

cd ${current}
rm -irf ${nginx_tarball}
rm -irf ${nginx_archivedir}
rm -irf ${openssl_tarball}
rm -irf ${openssl_archivedir}
rm -irf ${headers_more_tarball}
rm -irf ${headers_more_archivedir}

apt-get purge -y wget make build-essential libpcre3-dev zlib1g-dev libgd-dev

exit 0

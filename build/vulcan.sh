#!/bin/bash
set -e
mkdir -p /tmp/build
mkdir -p /tmp/build/local
mkdir -p /tmp/build/local/lib
mkdir -p /tmp/build/local/lib/sasl2

mkdir -p /app/local
mkdir -p /app/local/lib
mkdir -p /app/local/bin
mkdir -p /app/local/include
mkdir -p /app/apache
mkdir -p /app/php
mkdir -p /app/pgsql

cd /tmp
curl -O http://mirrors.us.kernel.org/ubuntu/pool/universe/m/mcrypt/mcrypt_2.6.8-1_amd64.deb
curl -O http://mirrors.us.kernel.org/ubuntu/pool/universe/libm/libmcrypt/libmcrypt4_2.5.8-3.1_amd64.deb
curl -O http://mirrors.us.kernel.org/ubuntu/pool/universe/libm/libmcrypt/libmcrypt-dev_2.5.8-3.1_amd64.deb
ls -tr *.deb > packages.txt
while read l; do
    ar x $l
    tar -xzf data.tar.gz
    rm data.tar.gz
done < packages.txt

cp -a /tmp/usr/include/* /app/local/include
cp -a /tmp/usr/lib/* /app/local/lib

export APACHE_MIRROR_HOST="http://www.apache.org/dist"
# export APACHE_MIRROR_HOST="http://apache.mirrors.tds.net"

curl -L ftp://ftp.andrew.cmu.edu/pub/cyrus-mail/cyrus-sasl-2.1.25.tar.gz -o /tmp/cyrus-sasl-2.1.25.tar.gz
#echo "downloading libmemcached"
#curl -L https://launchpad.net/libmemcached/1.0/1.0.16/+download/libmemcached-1.0.16.tar.gz -o /tmp/libmemcached-1.0.16.tar.gz
echo "downloading PCRE"
curl -L http://ftp.cs.stanford.edu/pub/exim/pcre/pcre-8.32.tar.gz -o /tmp/pcre-8.32.tar.gz
echo "downloading apr"
curl -L ${APACHE_MIRROR_HOST}/apr/apr-1.5.0.tar.gz -o /tmp/apr-1.5.0.tar.gz
echo "downloading apr-util"
curl -L ${APACHE_MIRROR_HOST}/apr/apr-util-1.5.3.tar.gz -o /tmp/apr-util-1.5.3.tar.gz
echo "downloading httpd"
curl -L ${APACHE_MIRROR_HOST}/httpd/httpd-2.4.9.tar.gz -o /tmp/httpd-2.4.9.tar.gz
echo "downloading php"
curl -L http://us.php.net/get/php-5.5.9.tar.gz/from/us2.php.net/mirror -o /tmp/php-5.5.9.tar.gz
#echo "downloading pecl-memcached"
#curl -L http://pecl.php.net/get/memcached-2.1.0.tgz -o /tmp/memcached-2.1.0.tgz
echo "download zlib"
curl -L http://zlib.net/zlib-1.2.8.tar.gz -o /tmp/zlib-1.2.8.tar.gz
# echo "downloading pecl zip extension"
# curl -L http://pecl.php.net/get/zip-1.10.2.tgz -o /tmp/zip-1.10.2.tgz
echo "download PGSQL"
curl -L http://ftp.postgresql.org/pub/source/v9.3.0/postgresql-9.3.0.tar.gz -o /tmp/postgresql-9.3.0.tar.gz
#echo "libmcrypt"
#curl -L http://pkgs.fedoraproject.org/repo/pkgs/libmcrypt/libmcrypt-2.5.7.tar.gz/b1be163143f8e8ed0474beeb642b3bad/libmcrypt-2.5.7.tar.gz -o /tmp/libmcrypt-2.5.7.tar.gz

#tar -C /tmp -xzf /tmp/libmcrypt-2.5.7.tar.gz
tar -C /tmp -xvzf /tmp/cyrus-sasl-2.1.25.tar.gz
#tar -C /tmp -xvzf /tmp/libmemcached-1.0.16.tar.gz
tar -C /tmp -xvzf /tmp/pcre-8.32.tar.gz
tar -C /tmp -xvzf /tmp/httpd-2.4.9.tar.gz

tar -C /tmp/httpd-2.4.9/srclib -xvzf /tmp/apr-1.5.0.tar.gz
mv /tmp/httpd-2.4.9/srclib/apr-1.5.0 /tmp/httpd-2.4.9/srclib/apr

tar -C /tmp/httpd-2.4.9/srclib -xvzf /tmp/apr-util-1.5.3.tar.gz
mv /tmp/httpd-2.4.9/srclib/apr-util-1.5.3 /tmp/httpd-2.4.9/srclib/apr-util

tar -C /tmp -xvzf /tmp/php-5.5.9.tar.gz
#tar -C /tmp -xvzf /tmp/memcached-2.1.0.tgz
tar -C /tmp -xvzf /tmp/zlib-1.2.8.tar.gz
tar -C /tmp -xvzf /tmp/postgresql-9.3.0.tar.gz
# tar -C /tmp -xzf /tmp/zip-1.10.2.tgz

export CFLAGS='-g0 -O2 -s -m64 -march=core2 -mtune=generic -pipe '
export CXXFLAGS="${CFLAGS}"
export CPPFLAGS="-I/app/local/include"
export LD_LIBRARY_PATH="/app/local/lib"
# export MAKEFLAGS="-j5"
# export MAKE="/usr/bin/make $MAKEFLAGS"
export MAKE="/usr/bin/make"

#cd /tmp/libmcrypt-2.5.7
#./configure --prefix=/app/local --disable-posix-threads --enable-dynamic-loading --enable-static-link
#${MAKE} && ${MAKE} install

cd /tmp/zlib-1.2.8
./configure --prefix=/app/local --64
${MAKE} && ${MAKE} install

cd /tmp/pcre-8.32
./configure --prefix=/app/local --enable-jit --enable-utf8
${MAKE} && ${MAKE} install

cd /tmp/httpd-2.4.9
./configure --prefix=/app/apache --enable-rewrite --enable-so --enable-deflate --enable-expires --enable-headers --enable-proxy-fcgi --with-mpm=event --with-included-apr --with-pcre=/app/local
${MAKE} && ${MAKE} install

cd /tmp
git clone git://github.com/ByteInternet/libapache-mod-fastcgi.git
cd /tmp/libapache-mod-fastcgi/
patch -p1 < debian/patches/byte-compile-against-apache24.diff 
sed -e "s%/usr/local/apache2%/app/apache%" Makefile.AP2 > Makefile
${MAKE} && ${MAKE} install

cd /tmp/postgresql-9.3.0
./configure --prefix=/app/pgsql
${MAKE} && ${MAKE} install


cd /tmp/php-5.5.9
./configure --prefix=/app/php --with-pdo-pgsql --with-pgsql --with-mysql=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv --with-gd --with-curl=/usr/lib --with-config-file-path=/app/php --enable-soap=shared --with-openssl --enable-mbstring --with-mhash --enable-mysqlnd --with-pear --with-mysqli=mysqlnd --with-jpeg-dir --with-png-dir --with-mcrypt=/app/local --enable-static --enable-fpm --with-pcre-dir=/app/local --disable-cgi --enable-zip  --with-zlib=/app/local
${MAKE}
${MAKE} install

/app/php/bin/pear config-set php_dir /app/php
#echo " " | /app/php/bin/pecl install memcache
echo " " | /app/php/bin/pecl install apc-3.1.13
/app/php/bin/pecl install igbinary

cd /tmp/cyrus-sasl-2.1.25
./configure --prefix=/app/local
${MAKE} && ${MAKE} install
export SASL_PATH=/app/local/lib/sasl2

#cd /tmp/libmemcached-1.0.16
#./configure --prefix=/app/local
## the configure script detects sasl, but is still foobar'ed
#sed -i 's/LIBMEMCACHED_WITH_SASL_SUPPORT 0/LIBMEMCACHED_WITH_SASL_SUPPORT 1/' Makefile
#${MAKE} && ${MAKE} install

#cd /tmp/memcached-2.1.0
#/app/php/bin/phpize
#./configure --with-libmemcached-dir=/app/local \
#  --prefix=/app/php \
#  --enable-memcached-igbinary \
#  --enable-memcached-json \
#  --with-php-config=/app/php/bin/php-config \
#  --enable-memcached-sasl \
#  --enable-static
#${MAKE} && ${MAKE} install

# cd /tmp/zip-1.10.2
# /app/php/bin/phpize
# ./configure --prefix=/app/php --with-php-config=/app/php/bin/php-config --enable-static
# ${MAKE} && ${MAKE} install

echo '2.4.9' > /app/apache/VERSION
echo '5.5.9' > /app/php/VERSION
echo '9.3' > /app/pgsql/VERSION

cp -a /app/apache /tmp/build/
cp -a /app/php /tmp/build/
cp -a /app/pgsql /tmp/build/
cp -aL /app/local/lib/libpcre.so.1 /tmp/build/local/lib/
cp -aL /app/local/lib/libmcrypt.so.4 /tmp/build/local/lib/
# cp -aL /usr/lib/libmysqlclient.so.16 /tmp/build/local/lib/
# cp -aL /app/local/lib/libhashkit.so.2 /tmp/build/local/lib/
#cp -aL /app/local/lib/libmemcached.so.11 /tmp/build/local/lib/
# cp -aL /app/local/lib/libmemcachedprotocol.so.0 /tmp/build/local/lib/
# cp -aL /app/local/lib/libmemcachedutil.so.2 /tmp/build/local/lib/
#cp -aL /app/local/lib/sasl2/*.so.2 /tmp/build/local/lib/sasl2/

rm -rf /tmp/build/apache/manual/

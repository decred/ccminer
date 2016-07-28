#!/bin/sh
set -e

# Simple script to build a mostly static version of ccminer for decred
# for linux.
# This could definitely be smarter and not always rebuild the deps.
# You must already have installed the CUDA library to use this.
#
# 2016/04/26
# jolan@decred.org

touch build.log

echo "Downloading dependencies if needed."
mkdir -p ../ccminer-static
cd ../ccminer-static/
ZLIB=zlib-1.2.8
if [ ! -e $ZLIB.tar.gz ]
then
    wget -q http://zlib.net/$ZLIB.tar.gz
fi
CURL=curl-7.48.0
if [ ! -e $CURL.tar.gz ]
then
    wget -q https://curl.haxx.se/download/$CURL.tar.gz
fi
JANSSON=jansson-2.7
if [ ! -e $JANSSON.tar.gz ]
then
    wget -q http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
fi

PREF=$PWD
cd $PREF

rm -rf bin/ $CURL include/ $JANSSON lib/ share/ $ZLIB

echo "Building zlib."
tar -xzf $ZLIB.tar.gz
cd $ZLIB
./configure --static --prefix=$PREF >> build.log 2>&1
make install >> build.log 2>&1
cd ..

echo "Building curl."
tar -xzf $CURL.tar.gz
cd $CURL
./configure --disable-rt --disable-rtsp --disable-libcurl-option --disable-ipv6 --disable-verbose --without-ca-bundle --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smb --disable-smtp --disable-gopher --disable-ftp --disable-file --disable-dict --disable-unix-sockets --disable-manual --without-libidn --without-librtmp --without-libssh2 --disable-ldap --disable-ldaps --disable-shared --enable-static --prefix=$PREF >> build.log 2>&1
make install >> build.log 2>&1
cd ..

echo "Building jansson."
tar -xzf $JANSSON.tar.gz
cd $JANSSON
CC=clang Cxx=clang++ ./configure --without-shared --enable-static --prefix=$PREF >> build.log 2>&1
make install >> build.log 2>&1
cd ..

# gcc6/clang on arch don't work so just force to gcc5 for now
export PATH="$PATH:/opt/cuda/bin/"
export CC="gcc-5"
export CXX="g++-5"

echo "Building ccminer."
cd ..
cd ccminer
PKG_CONFIG_LIBDIR=$PREF/lib/pkgconfig/ ./autogen.sh >> build.log 2>&1
env LD_LIBRARY_PATH="$PREF/lib" \
        PKG_CONFIG_LIBDIR=$PREF/lib/pkgconfig/ \
        ac_cv_path__libcurl_config=$PREF/bin/curl-config \
        ./configure --with-cuda=/opt/cuda >> build.log 2>&1
make -j8 >> build.log 2>&1
echo "Build complete."

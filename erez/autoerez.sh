#!/bin/sh

set -e

export LC_ALL=POSIX

base="`pwd`"
install="$base"/install
BUILD="$base"/build
export BUILD

here="`dirname $0`"
pushd "`dirname $here`"
src="`pwd`"
popd

mkdir -p build install

pushd build
export CC="cc -O3"
ln -sfn "$install" ./=install
"$src"/configure
"$src"/mkx
"$src"/mkx install
popd

t=erez-data-20070131.tar.gz
f=mirna454.txt.gz; if [ ! -e $f ]; then tar xzf $t $f; fi
f=chromFa.zip; if [ ! -e $f ]; then tar xzf $t $f; fi

PATH="$install/bin:$PATH"

ln -sf "$src"/erez/Makefile ./
make $*

# arch-tag: Tom Clegg Tue Jan 30 15:49:59 PST 2007 (autoerez.sh)

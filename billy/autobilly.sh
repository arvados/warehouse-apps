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

unzip -n chromFa.zip "chr?.fa" "chr??.fa"

PATH="$install/bin:$PATH"

ln -sf "$src"/billy/Makefile ./
make $*

# arch-tag: Tom Clegg Wed Nov 29 02:17:16 PST 2006 (autobilly.sh)

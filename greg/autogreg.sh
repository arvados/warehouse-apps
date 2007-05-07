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

ln -sf "$src"/greg/Makefile ./
make $*

# arch-tag: Tom Clegg Sun Mar  4 15:38:09 PST 2007 (autogreg.sh)

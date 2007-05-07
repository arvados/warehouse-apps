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
export CXXFLAGS="-O3"
export CFLAGS="-O3"
ln -sfn "$install" ./=install
"$src"/configure
"$src"/mkx
"$src"/mkx install
popd

PATH="$install/bin:$src/align-call:$PATH"

ln -sf "$src"/align-call/Makefile ./
make $*

# arch-tag: Tom Clegg Fri Mar 16 20:43:44 PDT 2007 (align-call/autoalign.sh)

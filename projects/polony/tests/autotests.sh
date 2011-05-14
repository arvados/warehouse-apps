#!/bin/bash

set -e

export LC_ALL=POSIX

export "CC=${CC-cc -O3}"

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
ln -sfn "$install" ./=install
"$src"/configure
"$src"/mkx
"$src"/mkx install
popd

dpkg -x "$base"/libwarehouse-perl_*_all.deb "$install"

PATH="$install/bin:$PATH"

for f in "$src"/tests/test-*.sh
do
  bash -e "$f"
done

echo "All tests completed."

# arch-tag: Tom Clegg Sun Feb  4 16:50:25 PST 2007 (tests/autotests.sh)

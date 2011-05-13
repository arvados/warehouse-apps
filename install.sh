#!/bin/bash

set -e

if [ "$1" = "" ]
then
  echo >&2 usage: $0 install_base_dir
  exit 1
fi

(cd warehouse; ./build_deb.sh)

ln -sfn "$1" install
./tests/autotests.sh

#!/bin/sh

################################################################
# Copyright (C) 2006 Harvard University
# Author: Tom Clegg
# 
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
# 

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

PATH="$install/bin:$PATH"

ln -sf "$src"/madeleine/Makefile ./
make $*

# arch-tag: Tom Clegg Fri Dec  8 18:24:28 PST 2006 (automadeleine.sh)

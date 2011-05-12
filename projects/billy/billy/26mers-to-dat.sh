# 26mers-to-dat.sh: 
#
################################################################
# Copyright (C) 2006 Harvard University
# Authors: Thomas Lord
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


cat 26mers.txt \
| (
    (
      cat << HERE
#: taql-0.1/text
# field "chrom0" "sym"
# field "start" "uint32"
# field "end" "uint32"
# field "chrom1" "sym"
# field "pos" "uint32"
# field "mer0" "uint64"
# field "mer1" "uint64"
#.
HERE
    ) ; 

    ( 
       echo "16 i" ; 
       sed -e '/^>/s/>\([^,]*\), start:\([0-9]*\) end:\([0-9]*\) \([^.]*\)\.\([0-9]*\).*/["\1" \2 \3 "\4" \5 ] n/' \
           -e 't' \
           -e 's/A/0/g' \
           -e 's/C/1/g' \
           -e 's/G/2/g' \
           -e 's/T/3/g' \
           -e 's/N/8/g' \
           -e 's/^\(......\)\(.......\)\(......\)\(.......\)/+\2-\1+\4-\3/' \
           -e 's/-\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)/\6\5\4\3\2\1/g' \
           -e 's/+\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)/\7\6\5\4\3\2\1/g' \
           -e 's/^\(.............\)\(.............\)$/FFF\1 n [ ] n FFF\2 p c/' \
    ) \
    | dc
  ) \
| tread

# arch-tag: Thomas Lord Mon Nov  6 14:06:55 2006 (billy/26mers-to-dat.sh)

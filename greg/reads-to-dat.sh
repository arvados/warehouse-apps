################################################################
# Copyright (C) 2006 Harvard University
# Authors: Tom Clegg
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

(
    cat <<EOF
#: taql-0.1/text
# field "mer0" "uint64"
# field "mer1" "uint64"
#.
EOF
    cut -f1 | sed -e 's/\(......\).\(......\)\(......\).\(......\)/\1\2 \3\4/'
) | gread

# arch-tag: tomc Sun Mar  4 15:29:34 PST 2007 (greg/reads-to-dat.sh)

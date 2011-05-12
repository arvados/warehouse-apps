# 26mers-to-dat.pl:
#
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

open (STDOUT, "|gread") or die "$!";

print q{#: taql-0.1/text
# field "chrom0" "sym"
# field "start" "uint32"
# field "end" "uint32"
# field "chrom1" "sym"
# field "pos" "uint32"
# field "mer0" "uint64"
# field "mer1" "uint64"
#.
};

while(<>)
{
    $_ .= scalar <>;
    tr/\r\n.,:>/ /;
    s/^ //;
    my @in = split;
    substr ($in[7], 12, 2) = " ";
    print qq{"$in[0]" $in[2] $in[4] "$in[5]" $in[6] $in[7]\n};
}

# arch-tag: tomc Sun Nov 12 00:29:49 PST 2006 (billy/26mers-to-24mers-dat.sh)

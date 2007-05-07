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

open (STDOUT, "|gread") or die "$!";

print q{#: taql-0.1/text
# field "pos0" "uint32"
# field "pos1" "uint32"
# field "gap0" "int8"
# field "gap1" "int8"
# field "mer0" "uint64"
# field "mer1" "uint64"
#.
};

while (<>) {
    tr/\r\n//;
    my (@in) = split;
    my (@start, @end);
    if (@in == 38) {
	@start = ($in[33], $in[34]);
	@gap = ($in[35] - 12, $in[36] - 12);
    } elsif (@in == 33) {
	@start = (0, 0);
	@gap = (-1, -1);
    } elsif (@in == 28) {
	# eg. "YS1_T38_24bases.rawcalls"
	@start = (0, 0);
	@gap = (-1, -1);
    } else {
	die "Bad input format";
    }
    my (@mers) = ($in[0] . substr($in[1], 1),
		  $in[2] . substr($in[3], 1));
    print "@start @gap @mers\n";
}

# arch-tag: Tom Clegg Fri Dec  8 18:20:41 PST 2006 (madeleine/y2rawcalls-to-12mers.sh)

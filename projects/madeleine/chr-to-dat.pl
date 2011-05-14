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

$n_mers = 12;

if ($ARGV[0] eq "-n" && @ARGV > 1) {
    $n_mers = $ARGV[1] + 0;
    shift @ARGV;
    shift @ARGV;
}

open (STDIN, "grep -v '^>' | tr -d '\r\n' | fold -w $n_mers |");
open (STDOUT, "| gread");

print <<HERE;
#: taql-0.1/text
# field "mer0" "uint64"
#.
HERE
    ;

while(<>){ print; if (!/\n$/) { print "\n"; } }

# arch-tag: Tom Clegg Fri Dec  8 22:10:05 PST 2006 (madeleine/chr-to-dat.sh)

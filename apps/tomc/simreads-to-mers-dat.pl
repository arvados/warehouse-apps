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

my @mersizes;
while ($ARGV[0] =~ /^\d+$/)
{
    push @mersizes, shift @ARGV;
}

print q{#: taql-0.1/text};
for (0..$#mersizes)
{
    print qq{\n# field "mer$_" "uint64"};
}
print q{
# field "masked" "uint32"
# field "start" "uint32"
# field "orient" "uint8"
# field "gap0" "uint32"
# field "gap1" "uint32"
# field "gap2" "uint32"
#.};

pop @mersizes;
while(<>)
{
    chomp;
    my @in = split;
    my $strpos = -1;
    for (@mersizes)
    {
	$strpos += $_ + 1;
	substr ($in[0], $strpos, 0) = " ";
    }
    for (1, 2, 4, 5, 6)
    {
	$in[$_] = hex($in[$_]);
    }
    print "@in\n";
}

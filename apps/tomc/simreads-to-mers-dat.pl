#!/usr/bin/perl

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

open (STDOUT, "|gread") or die "gread: $!";

my @mersizes = @ARGV;
@ARGV = ();

print qq{#: taql-0.1/text\n};
for (0..$#mersizes)
{
    print qq{# field "mer$_" "uint64"\n};
}
print qq{# field "aref" "sym"\n};
for (0..$#mersizes)
{
    print qq{# field "apos$_" "uint64"\n};
}
print qq{# field "aside" "uint8"\n};
print qq{#.\n};

while(<>)
{
    chomp;
    my @in = split;
    my $mers_merged = 0;
    for (0..$#mersizes)
    {
	if (length $in[$_] < $mersizes[$_])
	{
	    $in[$_] .= $in[$_+1];
	    splice @in, $_+1, 1;
	}
	$mers_merged++;
    }
    for (1 + $#mersizes)
    {
	$in[$_] = hex($in[$_]);
    }
    splice @in, $#mersizes + 1, 1; # drop "masked" field
    $in[$#mersizes + 1] =~ s/.*/"$&.fa"/; # chr1 -> "chr1.fa"
    for (1..$#mersizes+$mers_merged)
    {
	$in[$#mersizes + 2 + $_] += $in[$#mersizes + 1 + $_];
    }
    for (0..$mers_merged)
    {
	splice @in, $#mersizes + 3 + $_, 1;
    }
    print "@in\n";
}

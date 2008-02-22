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

my $didheader = 0;

sub oldheader
{
    return if $didheader;
    $didheader = 1;
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
}

sub newheader
{
    return if $didheader;
    $didheader = 1;
    print qq{#: taql-0.1/text
# field "mer0" "uint64"
# field "mer1" "uint64"
# field "read_id" "uint32"
# field "aref" "sym"
# field "apos0" "uint32"
# field "apos1" "uint32"
# field "agpos0" "uint32"
# field "agpos1" "uint32"
# field "aside" "uint8"
#.
};
}

while(<>)
{
    chomp;
    my @in = split;
    if (@in > @mersizes * 6)
    {
	# new format, more mers
	die "I only work with #mers=2" if @mersizes != 2;
	newheader();
	my @out = ($in[0].$in[1],
		   $in[2].$in[3],
		   $in[4],
		   '"'.$in[10].'"',
		   @in[12,14,13,15,16]);
	print "@out\n";
    }
    else
    {
	oldheader();
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
	$in[$#mersizes + 1] =~ s/.*/"$&"/; # chr1 -> "chr1"
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
}

close STDOUT or die "$!";

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

$thisreadid = 0;
@thisread = ();
flush ();

while (<>) {
    next if /^#/;
    chop;
    my ($readid, $chr, $pos, $before, $mer0, $gap0, $gap1, $mer1, $after,
	$gapsize, $errpos0, $errpos1, $reverse,
	$read0, $read1, $readchr, $readpos)
	= split;

    ++$pos;

    ++$readid;

    if (length ($before) > 8) {
	$before = substr ($before, -8);
    }
    $before = lc $before;

    $after = substr ($after, 0, 8);
    $after = lc $after;

    my ($gapmers) = "";
    if ($gap0 ne ".") {
	$gapmers = $gap0;
	if ($gap1 ne ".") {
	    $gapmers .= $gap1;
	}
    }
    $gapmers = lc $gapmers;

    my ($errpos) = ",";
    if ($errpos0 >= 0) {
	$errpos = "-" . (6 - $errpos0) . ",";
    }
    if ($errpos1 >= 0) {
	$errpos .= "+" . ($errpos1 + 1);
    }

    my ($read) = uc ($read0 . "CG" . $read1);
    if ($reverse) {
	$read =~ tr/ACGT/TGCA/;
	$read = reverse $read;
    }

    $readchr =~ s/\"//g;

    if ($thisreadid != $readid) {
	flush ();
	++$thisreadid;
	while ($thisreadid != $readid) {
	    print "$thisreadid\tNO,0\tERROR\n";
	    ++$thisreadid;
	}
    }
    if ($readpos == $pos && $readchr eq $chr && !$reverse) {
	$yes = 1;
    }

    push (@thisread,
	  join ("\t", $readid,
		$chr.".".$pos,
		$gapsize.",".$before.",".uc($mer0).",".$gapmers.",".uc($mer1).",".$after,
		$errpos,
		">".$readchr.", start:".$readpos." end:XXX"." ".$readchr.".".($readpos+6),
		$read)
	  . "\n");
}
flush ();
    

sub flush
{
    if (@thisread) {
	$yes = $yes ? "YES" : "NO";
	my ($n) = $#thisread + 1;
	for (@thisread) {
	    s/\t/\t$yes,$n\t/;
	}
	print @thisread;
    }
    @thisread = ();
    $yes = 0;
}

# arch-tag: Tom Clegg Fri Dec  8 21:59:08 PST 2006 (madeleine/madeleine-report.pl)

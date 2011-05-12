#!/usr/bin/perl

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
	$errpos = "-" . (12 - $errpos0) . ",";
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
		">".$readchr.", start:".$readpos." end:".($readpos+25)." ".$readchr.".".($readpos+12),
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

# arch-tag: Tom Clegg Wed Nov 29 01:45:19 PST 2006 (billy/billy-report.pl)

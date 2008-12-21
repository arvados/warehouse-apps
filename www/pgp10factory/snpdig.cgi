#!/usr/bin/perl

use strict;
use Fcntl ':flock';
use CGI;
use Digest::MD5 'md5_hex';
use POSIX;
use Warehouse;
use Warehouse::Manifest;
use Warehouse::Stream;
do "session.pm";

my $workdir = "./cache";
mkdir "$workdir/datablocks";

my $q = new CGI;
session::init($q);
my $sessionid = session::id();
print CGI->header (-cookie => [session::togo()]);

my $whc = new Warehouse;

my ($hash, $wantfile) = $ENV{PATH_INFO} =~ m{([0-9a-f]{32})(/\S+)?};

my $targetcolumn;

my $m = new Warehouse::Manifest (whc => $whc, key => $hash);
while (my $s = $m->subdir_next)
{
    $s->rewind;
    my $subdir = $s->name;
    while (my ($pos, $size, $file) = $s->file_next)
    {
	last if !defined $pos;
	next if length ($wantfile) && ".$wantfile" ne "$subdir/$file";

	# read alignments and snp calls

	my @calls;
	my @aligns;

	$s->seek ($pos);
	my $line = 0;
	while (my $dataref = $s->read_until ($pos + $size, "\n"))
	{
	    ++$line;
	    chomp $$dataref;
	    if ($$dataref =~ /^(\S+) \t (\d+) \t [A-Z]\S* \t [A-Z]\S* \t /x)
	    {
		push @calls, [ $1, $2, $$dataref ];
	    }
	    elsif ($$dataref =~ /^ \S+ \t (\S+) \t (\d+) \t [-\+] \t 
				.* \t (\d+) \t (\S+) \t \S+$/x
		   && $3 == length $4)
	    {
		push @aligns, [ $1, $2, $2 + $3 - 1, $$dataref ];
		$targetcolumn ||= $3;
	    }
	    else
	    {
		die "$0 $hash $subdir/$file line $line noparse $$dataref\n";
	    }
	}

	# sort

	@calls = sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] } @calls;
	@aligns = sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] } @aligns;

	# merge

	for (@calls)
	{
	    my ($chr, $pos, $inrec) = @$_;
	    my ($refbase, $callbase) = $inrec =~ /^\S+\s\d+\s(\S+)\s(\S+)/;

	    my $got;
	    my $html;
	    $html = qq{<a name="$chr,$pos"><code>$inrec</code></a>\n};

	    shift @aligns while ($chr gt $aligns[0]->[0]);
	    shift @aligns while ($chr eq $aligns[0]->[0] &&
				 $pos > $aligns[0]->[2]);
	    for (my $a = 0;
		 $a <= $#aligns &&
		 $chr eq $aligns[$a]->[0] &&
		 $pos >= $aligns[$a]->[1];
		 $a++)
	    {
		if ($pos <= $aligns[$a]->[2])
		{
		    $html .= qq{<pre>} if !$got;
		    $got = 1;
		    $html .=
			&ascii_art ($pos, $refbase, $callbase, $aligns[$a]);
		}
	    }
	    $html .= sprintf ("%*s%*s</pre>",
			      $targetcolumn+1, "*",
			      $targetcolumn+8, "*",
			      ) if $got;
	    $html .= "<br />" if !$got;

	    if ($callbase ne $refbase &&
		$callbase ne "N" &&
		$callbase ne "X")
	    {
		$html = qq{<div style="background: #ffc;">$html</div>};
	    }
	    print $html."\n";
	}
    }
}

sub ascii_art
{
    my ($target, $refbase, $callbase, $align) = @_;
    my $alignpos = $align->[1];
    my @align = split (/\t/, $align->[3]);
    if ($targetcolumn < $target - $alignpos)
    {
	$targetcolumn = $target - $alignpos;
    }
    my $indent = $targetcolumn - $target + $alignpos;
    my $art = sprintf "%${indent}.${indent}s", "";
    my $pretty = lc $align[-2];
    substr ($pretty, $target - $alignpos, 1) =~ tr/a-z/A-Z/;
    substr ($pretty, $target - $alignpos, 1) =~
	s{(.)}{
	    (fasta2bin($1) & (fasta2bin($callbase) || 0xf) & ~fasta2bin($refbase)) ? "<B>$1</B>" : $1}e;
    $art .= $pretty;
    $art .= "        ";
    $art .= $q->escapeHTML ($align[-1]);
    $art .= "\n";
    return $art;
}

sub fasta2bin
{
    my $x = shift;
    $x =~ tr/a-z/A-Z/;
    $x =~ tr/XACMGRSVTWYHKDBN/0123456789abcdef/;
    $x = hex($x);
    while ($x & ~0xf)
    {
	$x = ($x & 0xf) | ($x >> 4);
    }
    return $x;
}

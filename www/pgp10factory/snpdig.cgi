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

my @snplists = map {
    [ m{^/?(.*?)([0-9a-f]{32})?(/\S+)?$} ];
    # eg. {hash}/snplist.tab
    # eg. agrees-{hash}/snplist.tab
    # eg. disagrees-{hash}/snplist.tab
    # eg. isin-{hash}/snplist.tab
    # eg. hom-agrees-{hash}/snplist.tab
    # eg. het-disagrees-{hash}/snplist.tab
    # eg. call-{hash}/snplist.tab
    # eg. nocall-{hash}/snplist.tab
} split (/;/, $ENV{PATH_INFO});

my $targetcolumn;

my @callfilters;
while (@snplists)
{
    my ($filtertype, $hash, $wantfile) = @ { pop @snplists };

    if (!defined $hash)
    {
	unshift @callfilters, [ $filtertype ];
	next;
    }

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
		if ($$dataref =~ /^(\S+) \t (\d+) \t
				   [A-Z]\S* \t [A-Z]\S* \t /x)
		{
		    push @calls, [ $1, $2, $$dataref ];
		    next;
		}
		elsif ($$dataref =~ /^\S+ \t (\S+) \t (\d+) \t [-\+] \t
				      .* \t (\d+) \t (\S+) \t \S+$/x
		       && $3 == length $4)
		{
		    if (!@snplists)
		    {
			push @aligns, [ $1, $2, $2 + $3 - 1, $$dataref ];
			$targetcolumn ||= $3;
		    }
		    next;
		}
		elsif ($$dataref =~ /^(\S+) \t (\d+) $/x)
		{
		    push @calls, [ $1, $2, $$dataref ];
		    next;
		}
		die "$0 $hash $subdir/$file line $line noparse $$dataref\n";
	    }

	    # sort

	    @calls = sort
	    { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] } @calls;

	    @aligns = sort
	    { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] } @aligns;

	    # if this is just a filter (ie. not the first snplist specified)...

	    if (@snplists)
	    {
		unshift @callfilters, [ $filtertype, @calls ];
		next;
	    }

	    # merge

	    my $npositions;
	  CALL:
	    for (@calls)
	    {
		my ($chr, $pos, $inrec) = @$_;
		my ($refbase, $callbase) = $inrec =~ /^\S+\s\d+\s(\S+)\s(\S+)/;
		my @filterrecs;

		next CALL if $filtertype =~ /\bhet-/ && !is_het($callbase);
		next CALL if $filtertype =~ /\bhom-/ && !is_hom($callbase);
		next CALL if $filtertype =~ /\bcall-/ && is_nocall($callbase);
		next CALL if $filtertype =~ /\bnocall-/ && !is_nocall($callbase);

		for my $callfilter (@callfilters)
		{
		    splice @$callfilter, 1, 1
			while ($chr gt $callfilter->[1]->[0]
			       ||
			       ($chr eq $callfilter->[1]->[0] &&
				$pos > $callfilter->[1]->[1]));
		    my $has = ($chr eq $callfilter->[1]->[0] &&
			       $pos == $callfilter->[1]->[1]);

		    next CALL if !$has && $callfilter->[0] =~ "\bisin-";

		    my ($filterbase)
			= $callfilter->[1]->[2] =~ /^\S+\s\d+\s\S+\s(\S+)/;
		    
		    my $agree = (fasta2bin ($callbase)
				 == fasta2bin ($filterbase));
		    my $nocall = &is_nocall ($filterbase);
		    my $ignore = (&is_nocall ($callbase) ||
				  $nocall ||
				  !$has);
		    my $disagree = !$agree && !$ignore;
		    $agree &&= !$ignore;
		    next CALL if $callfilter->[0] =~ /\bagree-/ && !$agree;
		    next CALL if $callfilter->[0] =~ /\bdisagree-/ && !$disagree;
		    next CALL if $callfilter->[0] =~ /\bhet-/ && !is_het($filterbase);
		    next CALL if $callfilter->[0] =~ /\bhom-/ && !is_hom($filterbase);
		    next CALL if $callfilter->[0] =~ /\bnocall-/ && !$nocall;
		    next CALL if $callfilter->[0] =~ /\bcall-/ && $nocall || !$has;

		    push @filterrecs, $callfilter->[1]->[2] if $has;
		}

		my $got;
		my $html;
		$html = qq{<a name="$chr,$pos"><code><b>$inrec</b></code></a>\n};
		$html .= join ("", map { "<br><code>".$q->escapeHTML($_)."</code>" } @filterrecs);

		shift @aligns while (@aligns &&
				     $chr gt $aligns[0]->[0]);
		shift @aligns while (@aligns &&
				     $chr eq $aligns[0]->[0] &&
				     $pos > $aligns[0]->[2]);
		for (my $a = 0;
		     $a <= $#aligns &&
		     $chr eq $aligns[$a]->[0] &&
		     $pos >= $aligns[$a]->[1];
		     $a++)
		{
		    next unless ($pos <= $aligns[$a]->[2]);

		    $html .= qq{<pre>} if !$got;
		    $got = 1;
		    $html .=
			&ascii_art ($pos, $refbase, $callbase, $aligns[$a]);
		}
		if ($got)
		{
		    $html .= sprintf ("%*s%*s</pre>",
				      $targetcolumn+1, "*",
				      $targetcolumn+8, "*");
		}
		else
		{
		    $html .= "<br />";
		}

		if ($callbase ne $refbase &&
		    $callbase ne "N" &&
		    $callbase ne "X")
		{
		    $html = qq{<div style="background: #ffc;">$html</div>};
		}
		print $html."\n";
		++$npositions;
	    }
	    print qq{<hr noshade size=1 />$npositions positions listed\n};
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

sub is_het
{
    my $x = fasta2bin (@_);
    $x !~ /^(0|1|2|4|8|15)$/;
}

sub is_hom
{
    my $x = fasta2bin (@_);
    $x =~ /^(1|2|4|8)$/;
}

sub is_nocall
{
    my ($x) = shift;
    length($x) == 0 || $x =~ /^[NX]/i;
}

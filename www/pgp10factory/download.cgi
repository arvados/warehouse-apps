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

my $q = new CGI;
session::init($q);
my $sessionid = session::id();

my $whc = new Warehouse;

my ($hash) = $ENV{PATH_INFO} =~ m{([0-9a-f]{32})};
my $bigmanifest = readfile ("$workdir/$hash.bigmanifest");
if (!defined $bigmanifest &&
    open F, "<", "$workdir/$hash.outputs")
{
    $bigmanifest = "";
    for (<F>)
    {
	chomp;
	s/ .*//;
	if (-e "$workdir/$_.nomanifest")
	{
	    my @block;
	    my $length;
	    for (split (",", $_))
	    {
		my ($blockhash) = $whc->store_in_keep (hash => $_);
		push @block, $blockhash;
		$length += $1 if $blockhash =~ m{\+([0-9]+)};
	    }
	    $bigmanifest .= ". @block 0:$length:-\n";
	}
	else
	{
	    $bigmanifest .= $whc->fetch_block ($_);
	}
    }
    $bigmanifest =~ s{^(\S+ (\S+).*:)-\n}{
	$1 . "reads.txt" . (is_gz($2) ? ".gz" : "") . "\n";
    }e;
    $bigmanifest =~ s{^.*:cns.fq.txt\n}{}gm;
    $bigmanifest =~ s{ ([0-9a-f]{32}\S*)}{
	my ($blockhash) = $whc->store_in_keep (hash => $1);
	" " . $blockhash;
    }ge;
    writefile ("$workdir/$hash.bigmanifest", $bigmanifest);
    my ($bighash) = $whc->store_in_keep (dataref => \$bigmanifest);
}
printtar ($hash, $bigmanifest);

sub is_gz
{
    my ($blockhash) = @_;
    my $data = $whc->fetch_block ($blockhash);
    if ($data =~ /^[ -\177]{1024}/) { return 0; }
    else { return 1; }
}

sub writefile
{
    my $file = shift;
    open F, "+>>$file.tmp";
    flock F, LOCK_EX|LOCK_NB or do { close F; return; };
    seek F, 0, 0;
    truncate F, 0;
    print F @_;
    close F;
    rename "$file.tmp", "$file";
}

sub readfile
{
    my $file = shift;
    return undef if !open F, "<", $file;
    local $/ = undef;
    my $ret = <F>;
    close F;
    $ret;
}

sub printtar
{
    my $tarballname = shift;
    my $manifestdata = shift;

    my $tarballsize = 0;
    my $m = new Warehouse::Manifest (whc => $whc, data => \$manifestdata);

    $m->rewind;
    while (my $s = $m->subdir_next)
    {
	while (my ($pos, $size, $filename) = $s->file_next)
	{
	    last if !defined $pos;
	    $tarballsize += $size + 512;
	    my $pad = 512 - ($size & 511);
	    if ($pad != 512)
	    {
		$tarballsize += $pad;
	    }
	}
    }
    $tarballsize += 1024;
    my $endpad = "\0" x 1024;
    my $pad = 0x1000 - ($tarballsize & 0xfff);
    if ($pad != 0x1000)
    {
	$tarballsize += $pad;
	$endpad .= "\0" x $pad;
    }

    print CGI->header (
	-cookie => [session::togo()],
	-type => "application/x-tar",
	-attachment => "$tarballname.tar",
	"Content-length" => $tarballsize,
	);

    $m->rewind;
    while (my $s = $m->subdir_next)
    {
	my $dir = $s->name;
	$dir =~ s{^\.($|/)}{$1};
	while (my ($pos, $size, $filename) = $s->file_next)
	{
	    last if !defined $pos;

	    my $tarfilename = "$tarballname$dir/$filename";
	    substr ($tarfilename, 99) = "" if 99 < length $tarfilename;

	    my $tarheader = "\0" x 512;
	    substr ($tarheader, 0, length($tarfilename)) = $tarfilename;
	    substr ($tarheader, 100, 7) = sprintf ("%07o", 0644); # mode
	    substr ($tarheader, 108, 7) = sprintf ("%07o", 0); # uid
	    substr ($tarheader, 116, 7) = sprintf ("%07o", 0); # gid
	    substr ($tarheader, 124, 11) = sprintf ("%011o", $size);
	    substr ($tarheader, 136, 11) = sprintf ("%011o", scalar time);
	    substr ($tarheader, 156, 1) = "\0"; # typeflag
	    substr ($tarheader, 257, 5) = "ustar"; # magic
	    substr ($tarheader, 263, 2) = "00"; # version
	    substr ($tarheader, 265, 8) = "mogilefs";	# user
	    substr ($tarheader, 297, 8) = "mogilefs";	# group
	    substr ($tarheader, 329, 7) = "0000000";
	    substr ($tarheader, 337, 7) = "0000000";
	    substr ($tarheader, 148, 7) = sprintf ("%07o", tarchecksum($tarheader));
	    print $tarheader;

	    $s->seek ($pos);
	    while (my $dataref = $s->read_until ($pos + $size))
	    {
		print $$dataref;
	    }
	    my $pad = 512 - ($size & 511);
	    if ($pad != 512)
	    {
		print "\0" x $pad;
	    }
	}
    }
    print $endpad;
}

sub tarchecksum
{
  my $sum = 0;
  for (@_)
  {
    for (my $i=0; $i<length; $i++)
    {
      if ($i >= 148 && $i < 156) { $sum += 32; }
      else { $sum += ord(substr($_,$i,1)); }
    }
  }
  return $sum;
}

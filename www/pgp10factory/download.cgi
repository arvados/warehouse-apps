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

my $whc = new Warehouse;

my ($hash) = $ENV{PATH_INFO} =~ m{([0-9a-f]{32})};

my @pipelines;

if (-e "$workdir/$hash.islayout")
{
    my $layout = readfile ("$workdir/$hash");
    while ($layout =~ m{"reads": "([0-9a-f,]+)", "genome": "([0-9a-f,]+)"}g)
    {
	my $text = "pipeline=maq\nreads=$1\ngenome=$2\n";
	push @pipelines, {
	    id => md5_hex ($text),
	    reads => $1,
	    genome => $2,
	    text => $text,
	};
    }
}
elsif (-e "$workdir/$hash.ispipeline" && readlink "$workdir/$hash.download")
{
    my $text = readfile ("$workdir/$hash");
    my ($reads) = $text =~ /reads=(.*)/;
    my ($genome) = $text =~ /genome=(.*)/;
    push @pipelines, {
	id => $hash,
	reads => $reads,
	genome => $genome,
	text => $text,
    };
}
else
{
    print CGI->header (-status => "404 not found",
		       -type => "text/plain");
    print "404 Not Found\n\n$hash\n";
    exit 0;
}

for (@pipelines)
{
    my $downloadhash = readlink ("$workdir/".$_->{id}.".download");
    $_->{bigmanifest} = keepit ($_->{id}, $downloadhash);
    buildreadme ($_);
}
printtar ($hash, @pipelines);

sub buildreadme
{
    my $pipeline = shift;
    my $readme = qq{== Pipeline ID ==\n\n}.$pipeline->{id}.qq{\n\n};
    $readme .= qq{== Pipeline Specification ==\n\n}.$pipeline->{text}.qq{\n};
    for my $input (qw(reads genome))
    {
	if ($pipeline->{$input})
	{
	    my $Input = ucfirst $input;
	    $Input =~ s/^Genome$/Reference/;
	    my $inputhash = $pipeline->{$input};
	    $readme .= qq{== $Input ==\n\n$inputhash\n\n};
	    my $comment = readfile ("./session/$sessionid/$inputhash.comment")
		|| readfile ("$workdir/$inputhash.comment");
	    if ($comment)
	    {
		chomp $comment;
		$readme .= qq{$comment\n\n};
	    }
	}
    }
    $pipeline->{readme} = $readme;
}

sub keepit
{
    my $pipelinehash = shift;
    my $bigmanifesthash = shift;
    if (my $manifest = readfile ("$workdir/$pipelinehash.bigmanifest"))
    {
	return $manifest;
    }
    my $bigmanifest = $whc->fetch_block ($bigmanifesthash);
    $bigmanifest =~ s{ (([0-9a-f]{32})\S*)}{
	my $hash = $1;
	my $md5 = $2;
	my $blockhash = readlink "$workdir/datablocks/$md5.keep";
	if (!$blockhash)
	{
	    ($blockhash) = $whc->store_in_keep (hash => $hash);
	    symlink $blockhash, "$workdir/datablocks/$md5.keep";
	}
	" " . $blockhash;
    }ge;
    my ($bighash) = $whc->store_in_keep (dataref => \$bigmanifest);
    writefile ("$workdir/$pipelinehash.bigmanifest", $bigmanifest);
    return $bigmanifest;
}

sub writefile
{
    my $file = shift;
    open F, "+>>", "$file.tmp";
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
    my @pipelines = @_;

    my $tarballsize = 0;
    for my $pipeline (@pipelines)
    {
	$tarballsize += tarsize ($pipeline);
    }
    
    print CGI->header (
	-cookie => [session::togo()],
	-type => "application/x-tar",
	-attachment => "$tarballname.tar",
	"Content-length" => $tarballsize + tarpad_eof ($tarballsize),
	);

    for my $pipeline (@pipelines)
    {
	tarpipeline ($pipeline);
    }
    print "\0" x tarpad_eof ($tarballsize);
}

sub tarsize
{
    my $pipeline = shift;
    my $manifestdata = $pipeline->{bigmanifest};
    my $m = new Warehouse::Manifest (whc => $whc, data => \$manifestdata);
    $m->rewind;
    my $tarballsize = 0;
    if ($pipeline->{readme})
    {
	$tarballsize += length $pipeline->{readme};
	$tarballsize += 512 + tarpad ($tarballsize);
    }
    while (my $s = $m->subdir_next)
    {
	while (my ($pos, $size, $filename) = $s->file_next)
	{
	    last if !defined $pos;
	    $tarballsize += 512 + $size + tarpad ($size);
	}
    }
    return $tarballsize;
}

sub tarpad
{
    my $tarballsize = shift;
    return 0 if $tarballsize & 511 == 0;
    return 512 - ($tarballsize & 511);
}

sub tarpad_eof
{
    my $tarballsize = shift;
    $tarballsize += 1024;
    my $pad = 0x1000 - (($tarballsize + 1024) & 0xfff);
    return 1024 if $pad == 0x1000;
    return 1024 + $pad;
}

sub tarpipeline
{
    my $pipeline = shift;
    my $manifestdata = $pipeline->{bigmanifest};
    my $pipelinedir = $pipeline->{id};
    my $timestamp = readlink ("$workdir/".$pipeline->{id}.".finishtime_s")
	|| scalar time;
    my $m = new Warehouse::Manifest (whc => $whc, data => \$manifestdata);
    $m->rewind;
    if (length $pipeline->{readme})
    {
	my $tarfilename = "$pipelinedir/README.txt";
	my $size = length ($pipeline->{readme});
	my $header = tarheader ($tarfilename, $size, $timestamp);
	print $header;
	print $pipeline->{readme};
	print "\0" x tarpad ($size);
    }
    while (my $s = $m->subdir_next)
    {
	my $dir = $s->name;
	$dir =~ s{^\.($|/)}{$1};
	while (my ($pos, $size, $filename) = $s->file_next)
	{
	    last if !defined $pos;

	    my $tarfilename = "$pipelinedir$dir/$filename";
	    my $header = tarheader ($tarfilename, $size, $timestamp);
	    print $header;

	    $s->seek ($pos);
	    while (my $dataref = $s->read_until ($pos + $size))
	    {
		print $$dataref;
	    }
	    my $pad = tarpad ($size);
	    print "\0" x $pad if $pad;
	}
    }
}

sub tarheader
{
    my ($tarfilename, $size, $timestamp) = @_;

    substr ($tarfilename, 99) = "" if 99 < length $tarfilename;

    my $header = "\0" x 512;
    substr ($header, 0, length($tarfilename)) = $tarfilename;
    substr ($header, 100, 7) = sprintf ("%07o", 0644); # mode
    substr ($header, 108, 7) = sprintf ("%07o", 0); # uid
    substr ($header, 116, 7) = sprintf ("%07o", 0); # gid
    substr ($header, 124, 11) = sprintf ("%011o", $size);
    substr ($header, 136, 11) = sprintf ("%011o", $timestamp);
    substr ($header, 156, 1) = "\0";	   # typeflag
    substr ($header, 257, 5) = "ustar"; # magic
    substr ($header, 263, 2) = "00";	   # version
    substr ($header, 265, 4) = "root";  # user
    substr ($header, 297, 4) = "root";  # group
    substr ($header, 329, 7) = "0000000";
    substr ($header, 337, 7) = "0000000";
    substr ($header, 148, 7) = sprintf ("%07o", tarchecksum($header));

    return $header;
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

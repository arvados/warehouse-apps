#!/usr/bin/perl

use strict;

use Warehouse;
use Warehouse::Stream;
use Digest::MD5;
use HTTP::Request::Common;
use LWP::UserAgent;
use CGI;

my $remoteserver = $ENV{WAREHOUSE_SERVER};

my $q = new CGI;

my $path_info = $ENV{PATH_INFO};# /1234abcd/subdir1/testfile
$path_info =~ s,^/,,;		# 1234abcd/subdir1/testfile

my $wantrawmanifest = 0;

if ($path_info =~ /^([0-9a-f]{32})(\/=|\.txt)$/)
{
    $path_info = $1;
    $wantrawmanifest = 1;
}
elsif ($path_info !~ m,/,)
{
    # redirect .../whget.cgi/key -> .../whget.cgi/key/ so that
    # relative url's work predictably
    print $q->redirect ($ENV{REQUEST_URI}."/");
    exit 0;
}

my ($key, $path) = split ("/", $path_info, 2); # 1234abcd subdir1/testfile
my ($wantsubdir, $wantfile) = $path =~ m,^(.*?)([^/]*)$,; # subdir1 testfile

if ($wantsubdir eq "")
{
    $wantsubdir = "";
}
else
{
    $wantsubdir = "/".$wantsubdir;
    $wantsubdir =~ s,/$,,;
}

my $whc = new Warehouse ("warehouse_servers" => $remoteserver);

my $manifestblock;
if ($key =~ /^[0-9a-f]{32}$/) {
    $manifestblock = $whc->fetch_block ($key)
	or header_and_die (1, "fetch_block failed");
}
elsif ($key =~ /^[0-9a-f]{32}(,[0-9a-f]{32})+$/)
{
    $manifestblock = $key;
}
else
{
    $manifestblock = $whc->fetch_manifest_key_by_name ("/".$key)
	or do {
	    print $q->header (-status => 404,
			      -type => 'text/plain');
	    print "Not found: /$key.\n";
	    exit 0;
	};
}

my @manifesthash;
if ($manifestblock =~ /^[0-9a-f]{32}(,[0-9a-f]{32})*\n?$/)
{
    @manifesthash = split (",", $manifestblock);
    $manifestblock = $whc->fetch_block (shift @manifesthash)
	or header_and_die (1, "fetch_block failed");
}

if ($wantrawmanifest)
{
  print $q->header (-type=>"text/plain");
  print $manifestblock;
  while (@manifesthash)
  {
    $manifestblock = $whc->fetch_block (shift @manifesthash)
	or header_and_die (1, "fetch_block failed");
    print $manifestblock;
  }
  exit 0;
}

my $headerdone;

MANIFESTBLOCK:
while (length $manifestblock)
{
    $manifestblock =~ s/^([^\n]*)\n//
	or header_and_die (!$headerdone, "no newline at end of manifest");
    my @subdir = split (" ", $1);
    my $subdir_name = shift @subdir;

    $subdir_name =~ s/^\.//
	or header_and_die (!$headerdone, "subdir name '$subdir_name' does not start with period");

    if ($wantfile eq "")
    {
	if (!$headerdone)
	{
	    print $q->header (-type=>'text/html');
	    print "<pre>";
	    $headerdone = 1;
	}
	print "$subdir_name\n";
	while (@subdir)
	{
	    if ($subdir[0] =~ /^-\d+$/) { splice @subdir, 0, 2; }
	    elsif ($subdir[0] =~ /^[0-9a-f]{32}([-\+]\d+)?$/)
	    {
	      shift @subdir;
	    }
	    else
	    {
	      last;
	    }
	}
	foreach (@subdir)
	{
	    my ($pos, $size, $name) = split (":", $_, 3);
	    printf ("%12d %s\n",
		    $size,
		    "<a href=\".$subdir_name/$name\">$subdir_name/$name</a>");
	}
    }
    elsif ($subdir_name eq $wantsubdir)
    {
	my @hash;
	while (@subdir)
	{
	    if ($subdir[0] =~ /^-(\d+)$/)
	    {
		push @hash, splice @subdir, 0, 2;
	    }
	    elsif ($subdir[0] =~ /^[0-9a-f]{32}([-\+]\d+)?$/)
	    {
		push @hash, shift @subdir;
	    }
	    else
	    {
		last;
	    }
	}
	foreach (@subdir)
	{
	    if (/^(\d+):(\d+):\Q$wantfile\E$/)
	    {
		my ($pos, $size) = ($1, $2);
		my $stream = new Warehouse::Stream (whc => $whc,
						    hash => \@hash);
		$stream->seek ($pos);

		print $q->header (-type => guesstype ($wantfile),
				  -Content_length => $size);

		while (my $dataref = $stream->read_until ($pos+$size))
		{
		    print $$dataref;
		}
		exit 0;
	    }
	}
    }

    if (@manifesthash &&
	$Warehouse::blocksize > 2 * length $manifestblock)
    {
	my $nextblock = $whc->fetch_block (shift @manifesthash)
	    or header_and_die (!$headerdone, "fetch_block failed");
	$manifestblock .= $nextblock;
    }
}

if ($wantfile eq "")
{
    print "</pre>\n";
    exit 0;
}

print $q->header (-status=>404);
print "Not found: $wantfile in $wantsubdir\n";


sub header_and_die
{
    my $needheader = shift;
    if ($needheader)
    {
	print $q->header (-type=>'text/plain',
			  -status=>500);
	print @_;
	exit 1;
    }
    else
    {
	die @_;
    }
}


sub guesstype
{
    my $filename = shift;
    if ($filename =~ /\.tiff?$/i)
    {
	return 'image/tiff';
    }
    elsif ($filename =~ /\.jpe?g$/i)
    {
	return 'image/jpeg';
    }
    elsif ($filename =~ /\.txt$/i)
    {
	return 'text/plain';
    }
    elsif ($filename =~ /^(positions|cycles)$/i)
    {
	return 'text/plain';
    }
    return 'application/binary';
}

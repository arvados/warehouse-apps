#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 qw(md5_hex md5);
use DBI;
use CGI ':standard';
use Image::Magick;

my $q = new CGI;

my $png = $q->param ("format") eq "png";

print $q->header ($png ? 'image/png' : 'text/plain');

do '/etc/polony-tools/genomerator.conf.pl';

my $mogc;
for (qw(1 2 3 4 5))
{
    $mogc = eval {
	MogileFS::Client->new (domain => $main::mogilefs_default_domain,
			       hosts => [@main::mogilefs_trackers]);
      };
    last if $mogc;
}
die "$@" if !$mogc;

my $dsid = $q->param ('dsid');

my $positions = $mogc->get_file_data ("/$dsid/IMAGES/RAW/positions");

my @frame;
foreach (split ("\n", $$positions))
{
    my ($id, $x, $y) = /^(\d+)\s+([-\d\.]+)\s+([-\d\.]+)\s/;
    if (defined $id)
    {
	push @frame, [$id+1, $x, $y];
    }
}

my $gridw = $q->param ("gridw") || 50;
my $gridh = $q->param ("gridh") || 50;
my $imagew = $q->param ("imagew") || 401;
my $imageh = $q->param ("imageh") || 401;
my $gridsquarew = int ($imagew / $gridw);
my $gridsquareh = int ($imageh / $gridh);

my $minx;
my $miny;
my $maxx;
my $maxy;
my @allx;
my @ally;

foreach (@frame)
{
    my ($id, $x, $y) = @$_;
    if (!defined $minx || $x < $minx) { $minx = $x; }
    if (!defined $miny || $y < $miny) { $miny = $y; }
    if (!defined $maxx || $x > $maxx) { $maxx = $x; }
    if (!defined $maxy || $y > $maxy) { $maxy = $y; }
    push @allx, $x;
    push @ally, $y;
}

# smallx/smally - frames closer than this will be in the same grid spot
my $smallx = ($maxx-$minx)/$gridw/2;
my $smally = ($maxy-$miny)/$gridh/2;

my @gridx;			# smallest x pos of each grid square
my %gridx;			# smallest x pos of each frame x position
my $thisgridx;
foreach (sort { $a <=> $b } @allx)
{
    if (!defined $thisgridx ||
	$_ > $thisgridx+$smallx)
    {
	$thisgridx = $_;
	push @gridx, $_;
    }
    $gridx{$_} = $thisgridx;
}

my @gridy;
my %gridy;
my $thisgridy;
foreach (sort { $a <=> $b } @ally)
{
    if (!defined $thisgridy ||
	$_ > $thisgridy+$smally)
    {
	$thisgridy = $_;
	push @gridy, $_;
    }
    $gridy{$_} = $thisgridy;
}

my %id;
foreach (@frame)
{
    my ($id, $x, $y) = @$_;
    $id{$gridx{$x}}{$gridy{$y}} = $id;
}

my $image;
if ($png)
{
    $image = new Image::Magick;
    $image->Set (size=>$imagew."x".$imageh);
    $image->Read ("xc:white");
}

for (my $y = 0; $y < $gridh; $y++)
{
    my $thisgridy = $gridy[$y];
    for (my $x = 0; $x < $gridw; $x++)
    {
	my $thisgridx = $gridx[$x];
	my $id = $id{$thisgridx}{$thisgridy};
	if ($png)
	{
	    if (defined $id)
	    {
		my ($px, $py) = ($x * $gridsquarew+1, $y * $gridsquareh+1);
		my ($px2, $py2) = ($px + $gridsquarew-2, $py + $gridsquareh-2);
		$image->Draw (stroke=>"black",
			      fill=>"black",
			      primitive=>"rectangle",
			      points=>"$px,$py,$px2,$py2");
	    }
	}
	else
	{
	    if (defined $id) { print "$id\n"; }
	    else { print "-1\n"; }
	}
    }
}

$|=1;
if ($png)
{
    $image->Write('png:-');
}

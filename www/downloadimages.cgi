#!/usr/bin/perl

use strict;
use CGI ':standard';

my $q = new CGI;

my @cycle_list	= $q->param ('cycles[]');
my $dsid		= $q->param ('dsid');
my $frame_id 	= $q->param ('frame_id');
my $cid;

for $cid (@cycle_list) {
    my $nimages = $cid =~ /\D/ ? 4 : 1;
    my $imagesrc = "/$cid/";
    my $counter	= 1;
    my $image_file;
    
    if ($cid eq "999")
    {
	$imagesrc .= "WL_";
    }
    else
    {
	$imagesrc .= "SC_";
    }
    
    for (my $i=1; $i<=$nimages; $i++) {
	$image_file = $imagesrc
	    . sprintf ('%04d', (($frame_id - 1) * $nimages + $i));
	push @main::include, $image_file;
    }
}

$main::_keyprefix = "/$dsid/IMAGES/RAW/";
@main::include = sort { $a cmp $b } @main::include;

do "download.cgi";

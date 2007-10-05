#!/usr/bin/perl
use strict;
use CGI ':standard';

my $q = new CGI;
print $q->header;

my @cycle_list	= $q->param ('cycles[]');
my $dsid		= $q->param ('dsid');
my $frame_id 	= $q->param ('frame_id');
my $cid;

for $cid (@cycle_list) {
    my $nimages = $cid =~ /\D/ ? 4 : 1;
    my $imagesrc = "/$dsid/IMAGES/RAW/$cid/";
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
	
	while($counter <= $nimages) {
		$image_file = $imagesrc . sprintf('%04d',(($frame_id - 1) * $nimages + $counter));		
	    print "$image_file\n";
		$counter++;
	}
}

#!/usr/bin/perl
use strict;
use warnings;
#use CGI;
use GD;
use DBI;

use lib qw(/usr/local/polony-tools/current/apps/jer/modules/);
use WharehouseCache;
use WharehouseJobGraph;



# create the objects & globals
my $dbh = DBI->connect(dsn_vars())
	or die "Can't connect to cache db: $DBI::errstr\n"; 

my $job_list = {}; # a slice of the job database
my $job_count; # = keys($job_list)

# find some jobs to draw
my $sth = $dbh->prepare( q{ 
	select * from whjobstat
	where starttime is >= ?
	and finishtime is <= ?;
} );
$sth->execute($vp_starttime, $vp_finishtime);

# load the works into an array
if ($debuggery) { printf ("Reading from database...\n"); }
while (my $job = $sth->fetchrow_hashref()) {
	$job_list->{$job->{id}} = $job;
} 
$sth->finish;
$job_count = keys(%{$job_list})-1;








# create a new image
my $im = new GD::Image($default_width, $default_height);

my $fgc = $im->colorAllocate(180,180,180);
my $bgc = $im->colorAllocate(0,0,0);
my $pagec = $im->colorAllocate(64,64,64);

$im->fill(1,1,$pagec);

write_image($output_filename);


sub draw_job {
	$im->rectangle(
}

sub draw_key {
}

sub write_image {
	my $output_filename = shift;
	open (IMG, ">$output_filename") || die("Unable to open '$output_filename' for writing");
	binmode IMG;
	#flock(IMG, LOCK_EX);
	#seek(IMG, 0, SEEK_SET);
	print IMG $im->png;
	close(IMG);
}

sub draw_frame {
	my ($


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

#!/usr/bin/perl

use strict;
use MogileFS::Client;

do '/etc/polony-tools/config.pl';

my @trackers = split (",", $ENV{MOGILEFS_TRACKERS});
my $domain = $ENV{MOGILEFS_DOMAIN};
my $mogc = MogileFS::Client->new (domain => $domain,
				  hosts => [@trackers]);
if (@ARGV)
{
    foreach (@ARGV)
    {
	my @urls = $mogc->get_paths($_);
	print "$urls[0]\n";
    }
}
else
{
    while (<>)
    {
	chomp;
	my @urls = $mogc->get_paths($_);
	print "$urls[0]\n";
    }
}

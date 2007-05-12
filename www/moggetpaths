#!/usr/bin/perl

use strict;
use MogileFS::Client;

do '/etc/polony-tools/config.pl';

my @trackers = split (",", $ENV{MOGILEFS_TRACKERS});
my $domain = $ENV{MOGILEFS_DOMAIN};
my $mogc = MogileFS::Client->new (domain => $domain,
				  hosts => [@trackers]);
my @urls = $mogc->get_paths($ARGV[0]);
print $urls[0];

#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 qw(md5_hex md5);
use DBI;
use CGI ':standard';

my $q = new CGI;
print $q->header ("image/png");

do '/etc/polony-tools/config.pl';

my ($domain, $prefix) = split (",", $ENV{PATH_INFO});
$domain =~ s,^/,,;
$prefix =~ s,\.png$,,i;

print STDERR "$domain, $prefix\n";

my $mogc;
for (qw(1 2 3 4 5))
{
    $mogc = eval {
	MogileFS::Client->new (domain => $domain,
			       hosts => [@main::mogilefs_trackers]);
      };
    last if $mogc;
}
die "$@" if !$mogc;

my @keylist = $mogc->list_keys ($prefix, undef);
die "MogileFS::Client::list_keys() failed" if !@keylist;
my ($after, $keys) = @keylist;
exit if (!defined ($keys) || !@$keys);

my $key;
my $filter;
foreach (@$keys)
{
    my $convert = "convert";
    my $transform = "-normalize";

    if (/\.raw$/i)
    {
	$filter = "$convert -endian lsb -size 1000x1000 gray:- $transform png:-";
    }
    elsif (/\.raw.g?z$/i)
    {
	$filter = "zcat | $convert -endian lsb -size 1000x1000 gray:- $transform png:-";
    }
    elsif (/\.tiff?$/i)
    {
	$filter = "$convert tif:- $transform png:-";
    }
    elsif (/\.tiff?\.g?z$/i)
    {
	$filter = "zcat | $convert tif:- $transform png:-";
    }
    $key = $_;
    last if defined $filter;
}
exit if !defined $filter;

my @paths = $mogc->get_paths ($key);
exit if !@paths;
print STDERR "$domain, $prefix, $key, $filter, @paths\n";
exec ("wget -q -O - '$paths[0]' | $filter");

#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 qw(md5_hex md5);
use DBI;
use CGI ':standard';

my $q = new CGI;

do '/etc/polony-tools/config.pl';

my ($outputsize, $prefix, $domain);

my $path_info = $ENV{PATH_INFO};
$path_info =~ s,^/,,;
$domain = "images";
if ($path_info =~ /^(\d+),(.*)/)
{
    $outputsize = $1;
    $prefix = "/$2";
}
elsif ($path_info =~ /^(.*?),(.*)/)
{
    $domain = $1;
    $prefix = "/$2";
}
else
{
    $prefix = "/$path_info";
}

if (defined $ENV{"DSID"})
{
    my $dsid = $ENV{"DSID"};
    $prefix = "/$dsid/IMAGES/RAW" . $prefix;
}

my $type = "png";
if ($prefix =~ s,\.(jpg|jp2|png)$,,i) { $type = lc $1; }

print $q->header ("image/$type");

print STDERR "$domain, $prefix, $type, $outputsize\n";

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
    my $transform = "";
    $transform .= " -geometry ${outputsize}x${outputsize}\\>" if defined $outputsize;
    $transform .= " -normalize";

    if (/\.raw$/i)
    {
	$filter = "$convert -endian lsb -size 1000x1000 gray:- $transform $type:-";
    }
    elsif (/\.raw.g?z$/i)
    {
	$filter = "zcat | $convert -endian lsb -size 1000x1000 gray:- $transform $type:-";
    }
    elsif (/\.tiff?$/i)
    {
	$filter = "$convert tif:- $transform $type:-";
    }
    elsif (/\.tiff?\.g?z$/i)
    {
	$filter = "zcat | $convert tif:- $transform $type:-";
    }
    $key = $_;
    last if defined $filter;
}
exit if !defined $filter;

my @paths = $mogc->get_paths ($key);
exit if !@paths;
print STDERR "$domain, $prefix, $key, $filter, @paths\n";
exec ("wget -q -O - '$paths[0]' | $filter");

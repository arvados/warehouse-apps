#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 'md5_hex';

my @trackers = qw(localhost:6001);
my $hdr;
my $boundary;
my $mogc;
my %part;
my %param;

print "Content-type: text/plain\n\n";

while(<>)
{
    if (!defined ($boundary))
    {
	$boundary = $_;
	$hdr = 1;
    }
    elsif ($_ eq $boundary)
    {
	$part{content} =~ s/\r?\n$//;
	if (defined($part{filename}))
	{
	    print STDERR "$part{filename} $param{class} $param{domain}\n";
	    if (!defined ($mogc))
	    {
		$mogc = MogileFS::Client->new (domain => $param{domain},
					       hosts => [@trackers]);
	    }
	    my $fh = $mogc->new_file($part{filename}, $param{class});
	    print $fh $part{content};
	    if ($fh->close)
	    {
		# my $md5 = md5_hex($part{content});
		# could insert in md5 table
	    }
	    else
	    {
		$mogc->delete($part{filename});
	    }
	}
	else
	{
	    $param{$part{name}} = $part{content};
	}
	$hdr = 1;
	%part = ();
    }
    elsif ($hdr)
    {
	if (/^\r\n/)
	{
	    $hdr = 0;
	}
	elsif (/^Content-disposition:/i)
	{
	    if (/ name=\"(.*?)\"/)
	    {
		$part{name} = $1;
	    }
	    if (/ filename=\"(.*?)\"/)
	    {
		$part{filename} = $1;
	    }
	}
    }
    else
    {
	$part{content} .= $_;
    }
}

do { } while (-1 != wait);

# arch-tag: 89ed3513-fe5d-11db-9207-0015f2b17887


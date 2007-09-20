#!/usr/bin/perl

use strict;
use MogileFS::Client;
use Digest::MD5 'md5_hex';
use DBI;

do '/etc/polony-tools/config.pl';

my @trackers = qw(localhost:6001);
my $hdr;
my $boundary;
my $lastboundary;
my $lastchunk;
my $mogc;
my $eol;
my $dmid;
my %part;
my %param = (domain => $main::mogilefs_default_domain);

my $dbh = DBI->connect($main::mogilefs_dsn,
		       $main::mogilefs_username,
		       $main::mogilefs_password);

print "Content-type: text/plain\n\n";

while(<>)
{
    if (!defined ($boundary))
    {
	$boundary = $_;
	if (/\r\n$/)
	{
	    $eol = "\r\n";
	}
	else
	{
	    $eol = "\n";
	}
	s/($eol)/--$1/;
	$lastboundary = $_;
	$hdr = 1;
    }
    elsif ($_ eq $boundary || $_ eq $lastboundary)
    {
	if  (defined $lastchunk)
	{
	    $lastchunk =~ s/$eol$//;
	    writecontent ($lastchunk);
	}
	if (defined($part{filename}))
	{
	    if (!defined $dmid)
	    {
		my $sth = $dbh->prepare
		    ("select dmid from domain where namespace=?");
		$sth->execute ($param{domain})
		    or die "DBI query failed";
		($dmid) = $sth->fetchrow_array
		    or die "no dmid for namespace '$param{domain}'";
	    }

	    $dbh->do("delete md5 from md5,file"
		     . " where md5.fid=file.fid"
		     . " and dmid = ? and dkey = ?",
		     undef,
		     $dmid,
		     $part{filename});

	    flushcontent ();

	    $dbh->do("replace into md5 select fid, ? from file"
		     . " where dmid = ? and dkey = ?",
		     undef,
		     $part{md5}->hexdigest,
		     $dmid,
		     $part{filename});
	}
	else
	{
	    $param{$part{name}} = $part{content};
	}
	$hdr = 1;
	%part = ();
	$lastchunk = undef;
    }
    elsif ($hdr)
    {
	if (/^$eol/)
	{
	    $hdr = 0;
	}
	elsif (/^Content-length:\s*(\d+)/i)
	{
	    $part{length} = $1;
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
	if (!defined $mogc)
	{
	    $mogc = MogileFS::Client->new (domain => $param{domain},
					   hosts => [@trackers]);
	}
	writecontent ($lastchunk) if defined $lastchunk;
	$lastchunk = $_;
    }
}

do { } while (-1 != wait);

sub writecontent
{
    my $chunk = shift;

    if (!exists $part{md5})
    {
	$part{md5} = Digest::MD5->new;
    }
    $part{md5}->add ($chunk);

    if (exists $part{length} && exists $part{filename})
    {
	# The client told us the file size, so we can write to
	# MogileFS as it comes

	if (!exists $part{fh})
	{
	    $part{fh} = $mogc->new_file ($part{filename},
					 $param{class},
					 $part{length})
		or die "Error creating file: ".$mogc->errstr;
	}
	my $fh = $part{fh};
	print $fh $chunk;
    }
    else
    {
	# We don't know the file size, so we have to read the whole
	# thing before sending to MogileFS.  Start in RAM, and switch
	# to using a temporary file if it turns out to be a big file.

	if (exists $part{tempfilename})
	{
	    print TMP $chunk;
	}
	elsif (4000000 > length $part{content})
	{
	    # Apparently this is a big file.  Keep what we've got in
	    # RAM, but put the rest in a temporary file.

	    $part{tempfilename} = "/tmp/upload.$$";
	    open TMP, "+>$part{tempfilename}" or die "Can't open $part{tempfilename}: $!";
	    unlink $part{tempfilename};
	}
	else
	{
	    $part{content} .= $chunk;
	}
    }
}

sub flushcontent
{
    if (exists $part{fh})
    {
	close $part{fh} or die "Write failed: ".$mogc->errstr;
    }
    else
    {
	my $size = length $part{content};
	if (exists $part{tempfilename})
	{
	    $size += tell TMP;
	}
	my $fh = $mogc->new_file ($part{filename},
				  $param{class},
				  $size)
	    or die "Error creating file: ".$mogc->errstr;
	print $fh $part{content} or die "Write failed: ".$mogc->errstr;
	if (exists $part{tempfilename})
	{
	    my $buf;
	    seek TMP, 0, 0 or die "Can't rewind temp file: $!";
	    while (read TMP, $buf, 1000000)
	    {
		print $fh $buf or die "Write failed: ".$mogc->errstr;
	    }
	    close TMP;
	}
	close $fh or die "Close failed: ".$mogc->errstr;
    }
    delete $part{content};
    delete $part{fh};
}

# arch-tag: 89ed3513-fe5d-11db-9207-0015f2b17887


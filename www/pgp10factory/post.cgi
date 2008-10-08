#!/usr/bin/perl

use strict;
use CGI ':standard';
use Digest::MD5 'md5_hex';
use Fcntl ':flock';
use POSIX;

my $workdir = "/tmp/pgp10factory";
mkdir $workdir;
chmod 0777, $workdir;
die "$workdir does not exist and could not be created" unless -w $workdir;

my $q = new CGI;
print $q->header ("Content-type: text/plain");

my $want = $q->param ('q');
if ($want =~ /^[0-9a-f]{32}(,[0-9a-f]{32})*$/)
{
    if (open (F, "<", "$workdir/$want"))
    {
	local $/ = undef;
	my $data = <F>;
	close F;
	print $data;
	exit 0;
    }
}
elsif ($want =~ /^https?:\/\/.+/)
{
    my $urlmd5 = md5_hex ($want);
    my $data = initjson ($want);
    print $data;
    sysopen (F, "$workdir/$urlmd5.isurl.tmp", O_WRONLY|O_CREAT|O_EXCL) or die $!;
    syswrite F, $want;
    rename "$workdir/$urlmd5.isurl.tmp", "$workdir/$urlmd5.isurl" or die $!;

    sysopen (F, "$workdir/$urlmd5.tmp", O_WRONLY|O_CREAT|O_EXCL) or die $!;
    syswrite F, $data;
    rename "$workdir/$urlmd5.tmp", "$workdir/$urlmd5";
    close F;
}

sub initjson
{
    my $url = shift;
    return qq{
{
"workflow": {  "input": {  "id": "$url" },
     "pipeline": [ ],
     "message": "Source data at $url is queued for downloading." }
}
}
}

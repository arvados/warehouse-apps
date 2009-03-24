#!/usr/bin/perl

use strict;
use CGI ':standard';
use Digest::MD5 'md5_hex';
use Fcntl ':flock';
use POSIX;

my $workdir = "./cache";
mkdir $workdir;
chmod 0777, $workdir;
die "$workdir could not be created / is not writeable" unless -d $workdir && -w $workdir;

my $q = new CGI;
print $q->header ("Content-type: text/plain");

my $want = $q->param ('q');
if ($want =~ /^[0-9a-f]{32}(,[0-9a-f]{32})*$/)
{
    do_hash ($want);
}
elsif ($want =~ /^https?:\/\/.+/)
{
    do_url ($want);
}
else
{
    print qq{
{ "message": "Invalid somethingorother" }
};
}

sub do_url
{
    my ($want) = @_;
    my $urlmd5 = md5_hex ($want);
    if (my $inputhash = readlink "$workdir/$urlmd5.stored")
    {
	do_hash ($inputhash);
	return 1;
    }
    elsif (-s "$workdir/$urlmd5")
    {
	do_hash ($urlmd5);
	return 1;
    }
    my $data = initjson ($want);
    print $data;
    sysopen (F, "$workdir/$urlmd5.isurl.tmp", O_WRONLY|O_CREAT|O_EXCL) or die $!;
    syswrite F, $want;
    rename "$workdir/$urlmd5.isurl.tmp", "$workdir/$urlmd5.isurl" or die $!;

    sysopen (F, "$workdir/$urlmd5.tmp", O_WRONLY|O_CREAT|O_EXCL) or die $!;
    syswrite F, $data;
    rename "$workdir/$urlmd5.tmp", "$workdir/$urlmd5";
    close F;
    return 1;
}

sub do_hash
{
    my ($want) = @_;

    utime undef, undef, "$workdir/$want.ispipeline";

    if (-s "$workdir/$want" &&
	open (F, "<", "$workdir/$want"))
    {
	local $/ = undef;
	my $data = <F>;
	close F;
	print $data;
	return 1;
    }
    else
    {
	sysopen (F, "$workdir/$want", O_WRONLY|O_CREAT|O_EXCL);
	print qq{
{
"workflow": {  "input": {  "id": "$want" },
     "pipeline": [ ],
     "message": "Processing for this input set should begin shortly." }
}
};
return 1;
    }
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

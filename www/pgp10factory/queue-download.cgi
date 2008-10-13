#!/usr/bin/perl

use strict;
use CGI ':standard';
use CGI::Cookie;
use Digest::MD5 'md5_hex';
use Fcntl ':flock';
use POSIX;
do "session.pm";

my $workdir = "./cache";
mkdir $workdir;
chmod 0777, $workdir;
die "$workdir could not be created / is not writeable" unless -d $workdir && -w $workdir;

my $q = new CGI;
session::init($q);
print $q->header (-type => "text/plain",
		  -cookie => [session::togo()]);
my $sessionid = session::id();

my $want = $q->param ('q');
if ($want =~ /^[0-9a-f]{32}$/)
{
    do_requestid ($want);
}
elsif ($want =~ /^https?:\/\/.+/)
{
    do_url ($want);
}
else
{
    print qq{{ "message": "Invalid request.", "requestid": "$want" }};
}

sub do_url
{
    my ($want) = @_;
    my $requestid = md5_hex ($want."\@".time);
    sysopen (F, "$workdir/$requestid.isurl.tmp", O_WRONLY|O_CREAT|O_EXCL) or die $!;
    syswrite F, $want;
    rename "$workdir/$requestid.isurl.tmp", "$workdir/$requestid.isurl" or die $!;
    sysopen (F, "$workdir/$requestid", O_WRONLY|O_CREAT|O_EXCL);
    close F;

    sysopen (F, "session/$sessionid/$requestid.isurl", O_WRONLY|O_CREAT|O_EXCL);
    syswrite F, "$want";
    close F;

    return do_requestid ($requestid);
}

sub do_requestid
{
    my ($requestid) = @_;
    my $message = "Request id: $requestid<br />";
    my $stop = "false";
    if (my @stat = stat "$workdir/$requestid.isurl")
    {
	my $queuedtime = localtime $stat[9]; # request created
	$message .= qq{Download queued at $queuedtime.<br />};
    }
    if (my @stat = stat "$workdir/$requestid.wget-log")
    {
	my $activitytime = localtime $stat[9]; # log modified
	@stat = stat "$workdir/$requestid.lock";
	@stat = stat "$workdir/$requestid.fetched" if !@stat;
	my $startedtime = localtime $stat[9];
	$message .= qq{Download started at $startedtime.<br />Last activity at $activitytime.<br />};
    }
    if (my $inputhash = readlink "$workdir/$requestid.stored")
    {
	my @stat = lstat "$workdir/$requestid.stored";
	my $storedtime = localtime $stat[9];
	$message .= qq{Stored in warehouse at $storedtime.<br />Data hash: $inputhash<br />};
	$stop = "true";
    }
    if (!$message)
    {
	$message = "Invalid request id.";
    }
    $message =~ s/([\"\'])/\\\1/g;
    print qq{{
"message": "$message",
"requestid": "$requestid",
"stop": $stop
}};
    return 1;
}

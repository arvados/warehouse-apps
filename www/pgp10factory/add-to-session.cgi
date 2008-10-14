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
my $sessionid = session::id();

my $want = $q->param ('q');
if ($want =~ /^([0-9a-f]{32}(,[0-9a-f]{32})*)$/)
{
    sysopen F, "$workdir/$1", O_WRONLY|O_CREAT|O_EXCL;
    sysopen F, "./session/$sessionid/$1", O_WRONLY|O_CREAT|O_EXCL;
    print $q->header (-type => "text/plain",
		      -cookie => [session::togo()]);
    print "OK";
}
else
{
    print $q->header (-status => "400 Invalid request");
    print die;
}

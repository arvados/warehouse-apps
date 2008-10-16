#!/usr/bin/perl

use strict;
use CGI;
use Digest::MD5 'md5_hex';
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

my $id = $q->param ("id");
sysopen F, "$workdir/retryfailed-$id", O_WRONLY|O_CREAT|O_EXCL;
close F;
print qq{OK\n};


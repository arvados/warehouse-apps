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


my $json = $q->param ("layout");
my $jsonhash = md5_hex ($json);
if ((sysopen (F, "$workdir/$jsonhash.islayout", O_WRONLY|O_CREAT|O_EXCL) &&
     sysopen (F, "$workdir/$jsonhash", O_WRONLY|O_CREAT|O_EXCL) &&
     syswrite (F, $json) == length $json &&
     close F)
    ||
    (open (F, "<", "$workdir/$jsonhash") &&
     scalar <F> eq $json))
{
    sysopen F, "./session/$sessionid/$jsonhash", O_WRONLY|O_CREAT|O_EXCL;
    close F;
    print "$jsonhash";
}

#!/usr/bin/perl

use strict;
use CGI;
use POSIX;

my $workdir = "./cache";

my $q = new CGI;
print $q->header;
my $datahash = $q->param ("datahash");
if ($datahash =~ /^[0-9a-f]{32}[,0-9a-f]*$/ &&
    -e "$workdir/$datahash")
{
    if (sysopen F, "$workdir/$datahash.comment.tmp", O_WRONLY|O_CREAT|O_EXCL)
    {
	if (syswrite (F, $q->param ("comment"))
	    && rename ("$workdir/$datahash.comment.tmp",
		       "$workdir/$datahash.comment")
	    && close (F))
	{
	    print $q->param("comment");
	}
	else
	{
	    unlink "$workdir/$datahash.comment.tmp";
	}
    }
}

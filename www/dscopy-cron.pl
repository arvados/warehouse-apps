#!/usr/bin/perl

use strict;

do '/etc/polony-tools/config.pl';

my $dir = "/tmp";
opendir TMP, $dir or die "opendir $dir: $!";
while (my $filename = readdir TMP)
{
    if ($filename =~ /^dscopy:(.*)/)
    {
	my ($dsid, $remote) = split (":", $1, 2);
	print "$dsid $remote\n";
	if (fork() == 0)
	{
	    close STDIN;
	    open STDOUT, ">>$dir/$filename";
	    open STDERR, ">&STDOUT";
	    my $ret = system ("perl", "dscopy.pl", "/".$dsid."/", $remote);
	    if ($ret == 0)
	    {
#		unlink "$dir/$filename";
	    }
	    exit 0;
	}
    }
}

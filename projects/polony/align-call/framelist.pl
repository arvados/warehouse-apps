#!/usr/bin/perl

my $lastframe = -1;

if ($ARGV[0] =~ s/^mogilefs:\/\///)
{
    my @files = `mogtool listkey '$ARGV[0]/999/'`;
    for (@files)
    {
	chomp;
	if (/(\d+)\.[^\/]*$/)
	{
	    if ($1 > $lastframe)
	    {
		print "$1\n";
		$lastframe = $1;
	    }
	}
    }
}
if ($ARGV[0] =~ /:\/\//)
{
    my @html = `wget -O - -q '$ARGV[0]/999/'`;
    for (@html)
    {
	if (/href=\"[^\"\d]*(\d+)\./i)
	{
	    if ($1 > $lastframe)
	    {
		print "$1\n";
		$lastframe = $1;
	    }
	}
    }
}
else
{
    for (`ls '$ARGV[0]/999/'`)
    {
	tr/0-9//cd;
	print "$_\n";
    }
}

# arch-tag: Tom Clegg Sun Apr  8 11:58:29 PDT 2007 (align-call/framelist.pl)

#!/usr/bin/perl

my @ip;
foreach (`ifconfig`)
{
    if (my ($ip) = /inet addr:(\S+)/)
    {
	if ($ip !~ /^127\./)
	{
	    push @ip, $ip;
	}
    }
}

exit 1 if !@ip;

my @memcached;
opendir P, "/proc";
while (my $pid = readdir P)
{
    next if $pid !~ /^\d+$/;
    if (open F, "</proc/$pid/cmdline")
    {
	my $cmdline = do { local $/; scalar <F>; };
	close F;

	if ($cmdline =~ /^([^\0]*\/)?memcached\0/)
	{
	    my $port;
	    my $mem;
	    if ($cmdline =~ /\000-p\000(\d+)\000/)
	    {
		$port = $1;
	    }
	    else
	    {
		$port = 11211;
	    }
	    if ($cmdline =~ /\000-m\000(\d+)\000/)
	    {
		$mem = $1;
	    }
	    else
	    {
		print "# skip :$port because I can't find memory size (@ip)\n";
		next;
	    }
	    my $weight = int(($mem/200) * 2 / scalar @ip);
	    if ($weight < 1)
	    {
		print "# skip :$port because ${mem} MB has no weight (@ip)\n";
		next;
	    }
	    foreach my $ip (@ip)
	    {
		print qq{["$ip:$port", $weight],\n};
	    }
	}
    }
}
closedir P;

package Safepipe;

sub readfrom
{
    my $watcher = open (shift @_, "-|");
    return 0 if !defined $watcher;
    return 1 if $watcher == 0;

    my @caller = caller;
    my @children;
    my $haveoutput = 0;
    my $n = 0;
    my $lastreadpipe;
    while (@_)
    {
	$n++;
	my $command = shift @_;
	pipe ("read$n", "write$n") or die "@caller: $!";
	my $child = fork();
	die "@caller: $!" if !defined $child;
	if ($child == 0)
	{
	    close "read$n" or die "$!";
	    if (defined $lastreadpipe)
	    {
		open STDIN, "<&$lastreadpipe" or die "$!";
	    }
	    else
	    {
		close STDIN;
	    }
	    open STDOUT, ">&write$n" or die "$!";
	    exec $command;
	    die "@caller: $!";
	}
	close "write$n" or die "$!";
	$lastreadpipe = "read$n";

	push @children, $child;
    }
    if (defined $lastreadpipe)
    {
	open STDIN, "<&$lastreadpipe" or die "$!";
    }
    my $buf;
    while (read STDIN, $buf, 1048576)
    {
	print STDOUT $buf;
    }
    while (@children)
    {
	my $pid = wait;
	die "@caller: $pid exited $?" if $? != 0;
	pop @children;
    }
    close STDIN or die "@caller: $!";
    exit 0;
}

1;

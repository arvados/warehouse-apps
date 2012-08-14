package Safepipe;

sub readfrom
{
    my $watcher = open (shift @_, "-|");
    return 0 if !defined $watcher;
    return 1 if $watcher;

    my @caller = caller;
    my @children;
    my $haveoutput = 0;
    my $n = 0;
    my $lastreadpipe;
    my %command;
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

	    if (ref $command eq "ARRAY")
	    {
		while (@$command > 1)
		{
		    my $fh = shift @$command;
		    open "STAYOPEN", "<&", $fh;
		    $^F = 99999;
		    open $fh, "<&", "STAYOPEN";
		    $^F = 2;
		}
		$command = $command->[0];
	    }

	    exec $command;
	    die "$command: $! at $caller[1] line $caller[2].\n";
	}
	close "write$n" or die "$!";
	close $lastreadpipe or die "$!" if $lastreadpipe;
	$lastreadpipe = "read$n";

	push @children, 1;
	$command{$child} = ref $command ? $command->[-1] : $command;
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
    close STDIN or die "@caller: $!";
    close $lastreadpipe if defined $lastreadpipe;
    while (@children)
    {
	my $pid = wait;
	die "wait returned $pid" if $pid <= 0;
	die "@caller: $pid exited $?, command was ".$command{$pid} if $? != 0;
	pop @children;
	delete $command{$pid};
    }
    exit 0;
}

1;

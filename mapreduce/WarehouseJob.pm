package WarehouseJob;

sub queue_step
{
    my ($level, $input) = @_;
    printf STDERR ("+++mrjobstep %d %s+++\n", +$level, $input);
}

sub output
{
    my ($out) = @_;
    printf STDERR ("+++mrout %s+++\n", $input);
}

1;

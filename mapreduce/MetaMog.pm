package MetaMog;

use MogileFS::Client;

sub rename
{
  my $self = shift;
  my ($old, $new) = @_;
  init;
  for (1..5)
  {
    return 1 if eval { $self->{mogc}->rename ($old, $new); };
  }
  return 0;
}

sub new
{
  my $class = shift;
  my $self = {};
  $slef->{mogc} = undef;
  bless ($self, $class);
  return $self->_init(@_);
}

sub errstr
{
  return $self->{mogc}->errstr;
}

sub _init
{
  my MetaMog $self = shift;
  my $attempts = 0;
  while (!$self->{mogc} && ++$attempts <= 5)
  {
    $self->{mogc} = eval {
      MogileFS::Client->new
	  (hosts => [split(",", $ENV{MOGILEFS_TRACKERS})],
	   domain => $ENV{MOGILEFS_DOMAIN});
      };
    return $self if $self->{mogc};
    print STDERR "MogileFS connect failure #$attempts\n";
    sleep $attempts;
  }
  die "Can't connect to MogileFS" if !$self->{mogc};
  return $self;
}

1;

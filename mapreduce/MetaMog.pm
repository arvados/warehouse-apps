package MetaMog;

use MogileFS::Client;

sub rename
{
  my $self = shift;
  my ($old, $new) = @_;
  for (1..5)
  {
    return 1 if eval { $self->{mogc}->rename ($old, $new); };
  }
  return 0;
}

sub list_keys
{
  my $self = shift;
  my $prefix = shift;
  my @ret;
  my $after;
  my $keys;
  while (1)
  {
    ($after, $keys) = $self->{mogc}->list_keys ($prefix, $after);
    last if (!defined ($keys) || !@$keys);
    push @ret, @$keys;
  }
  return \@ret;
}

sub delete_all
{
  my $self = shift;
  my $prefix = shift;

  # try to make sure $prefix looks reasonably specific, eg. >= 2 slashes
  die "I refuse to delete all keys with prefix '$prefix'!"
      unless $prefix =~ m|\w/.+/|;

  my $ret = 1;
  my $after;
  my $keys;
  while (1)
  {
    ($after, $keys) = $self->{mogc}->list_keys ($prefix, $after);
    last if (!defined ($keys) || !@$keys);
    foreach (@$keys)
    {
      if ($self->{mogc}->delete ($_))
      {
	print STDERR "Deleted $_\n";
      }
      else
      {
	print STDERR "Error deleting $_: ".$self->errstr."\n";
	$ret = 0;
      }
    }
  }
  $ret;
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
  my $self = shift;
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

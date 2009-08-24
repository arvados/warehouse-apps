# -*- mode: perl; perl-indent-level: 2; -*-

package Warehouse::Stream;

use Warehouse;

=head1 NAME

Warehouse::Stream -- API for retrieving files from streams in the
warehouse.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use Warehouse::Stream;

 my $stream = Warehouse::Stream->new (whc => $whc,
				      hash => \@blocklist);

=head1 METHODS

=head2 new

 my $stream = Warehouse::Stream->new (whc => $whc,
				      hash => \@blocklist);

 my $stream = Warehouse::Stream->new (whc => $whc,
				      subdir => $line_from_manifest);

 my $stream = Warehouse::Stream->new (whc => $whc);

Creates a new stream.  Returns the new object on success.  Dies on
failure.

=cut

sub new
{
  my $class = shift;
  my $self = { @_ };
  bless ($self, $class);
  return $self->_init;
}

sub _init
{
  my Warehouse::Stream $self = shift;
  $self->{myhashes} = \@{$self->{hash}} if exists $self->{hash};
  $self->{bufpos} = 0;
  $self->{bufcursor} = 0;
  $self->{buf} = "";
  $self->{async_writes} = 0;
  $self->rewind;
  return $self;
}

sub copy
{
  my $self = shift;
  my $copy = { %$self };
  bless $copy, ref $self;
  $copy->{myhashes} = [ @ {$self->{myhashes}} ] if exists $self->{myhashes};
  $copy->{hash} = [ @ {$self->{hash}} ] if exists $self->{hash};
  return $copy;
}



=head2 name

 my $name = $stream->name;

Get this stream's name (aka subdirname).

 $stream->name ($newname);

Set the stream's name.

=cut

sub name
{
  my $self = shift;
  if (@_)
  {
    $self->{name} = shift;
    die "name must be \".\" or start with \"./\", and must not end with \"/\""
	unless $self->{name} eq "."
	|| $self->{name} =~ m,^\./.*[^/]$,;
  }
  return $self->{name};
}



=head2 as_string

 my $one_line_of_manifest = $stream->as_string;

Returns a newline-terminated string which can be included as a line in
a manifest, and passed as a "subdir" to L</new>.

=cut

sub as_string
{
  my $self = shift;
  if ($self->{subdir})
  {
    return $self->{subdir}."\n";
  }

  if (exists $self->{write_buf})
  {
    $self->_write_flush (1) or die "_write_flush failed";

    die "as_string called while still writing ".$self->{write_filename}
	if exists $self->{write_filename};

    my $hashlistref = $self->{myhashes};
    if (!@$hashlistref)
    {
      $hashlistref = [ "d41d8cd98f00b204e9800998ecf8427e+0" ];
    }

    return join (" ",
		 $self->name,
		 @$hashlistref,
		 @{$self->{myfiles}}) . "\n";
  }

  die "as_string not supported unless constructed with subdir arg, or write_* used"
      unless defined $self->{subdir};
}



=head2 as_key

 my $key = $stream->as_key;

Returns a key (comma-separated list of hashes) -- like as_string, but
no subdir name or filenames, and commas instead of spaces.

=cut

sub as_key
{
  my $self = shift;

  if (exists $self->{write_buf})
  {
    $self->_write_flush (1) or die "_write_flush failed: ".$self->{whc}->errstr;

    die "as_string called while still writing ".$self->{write_filename}
	if exists $self->{write_filename};

    return join (",",
		 map { /^([0-9a-f]{32})/; $1; } @{$self->{myhashes}});
  }

  die "as_key not supported unless write_* used";
}



=head2 clear

 $stream->clear;

Empty the stream of all data and files, presumably in preparation for
a sequence of L</write_start>, L</write_data>, L</write_finish>, and
L</as_string> operations.

=cut

sub clear
{
  my $self = shift;
  delete $self->{subdir};
  delete $self->{write_filename};
  $self->{myhashes} = [];	# hashes of completed/written blocks
  $self->{myfiles} = [];	# pos:size:name of write_finished files
  $self->{write_buf} = "";	# data yet to be written to warehouse
  $self->{write_pos} = 0;	# total stream bytes = pos at end of write_buf
}



=head2 write_hint

 $stream->write_hint (keep => 1);

=cut

sub write_hint
{
  my $self = shift;
  my %hint = @_;
  map { $self->{"write_hint_$_"} = $hint{$_} } keys %hint;
}



=head2 write_start

 $stream->write_start ($filename);

Add a file to the end of the stream.  This will be the "current file"
when you use L</write_data>.

Use L</clear> first.

=cut

sub write_start
{
  my $self = shift;
  my $filename = shift;
  $self->{write_filename} = $filename;
  $self->{write_filepos} = $self->{write_pos};
  die "write_start without clear" if !defined $self->{write_pos};
}



=head2 write_data

 $stream->write_data ($dataref);

Append data to the current (last) file in the stream.  This dies if
you didn't use L</write_start> to indicate a filename.

=cut

sub write_data
{
  my $self = shift;
  my $data = shift;
  die "write_data without matching write_start"
      if !defined $self->{write_filename};
  my $dataref = ref $data ? $data : \$data;

  $self->{write_pos} += length $$dataref;
  $self->{write_buf} .= $$dataref;
  $self->_write_flush;
}



sub _write_flush
{
  my $self = shift;
  my $flushall = shift;
  while (length ($self->{write_buf}))
  {
    my $writesize = length $self->{write_buf};
    if ($writesize >= $Warehouse::blocksize)
    {
      $writesize = $Warehouse::blocksize;
    }
    elsif (!$flushall)
    {
      return 1;
    }

    if (!$self->_finish_async_writes ($ENV{ASYNC_WRITE} - 1))
    {
      warn "_finish_async_writes failed";
      return undef;
    }
    my $pid;
    my $r;
    my $w;
    if ($ENV{ASYNC_WRITE} > $self->{async_writes} &&
	pipe ($r, $w) &&
	defined ($pid = fork()))
    {
      if ($pid > 0)
      {
	++$self->{async_writes};
	printf STDERR ("spawned child %d reader %s\n",
		       $pid, $r)
	    if $ENV{DEBUG_ASYNC_WRITE};
	close $w;
	push @{$self->{myhashes}}, { pid => $pid, readhandle => $r };
      }
      else
      {
	close $r;
	close STDOUT;
	close STDIN;
	select $w;
	my $hash;
	for (1..4)
	{
	  $hash = $self->{whc}->store_block (substr ($self->{write_buf},
						     0, $writesize));
	  last if $hash;
	}
	if ($hash)
	{
	  print $w $hash;
	  close $w;
	  exit 1 if $ENV{DEBUG_ASYNC_WRITE_FAIL};
	  exit 0;
	}
	warn "async store_block failed after 4 attempts: " . $self->{whc}->errstr;
	exit 1;
      }
    }
    else
    {
      my $hash;
      for (1..4)
      {
	$hash = $self->{whc}->store_block (substr ($self->{write_buf},
						   0, $writesize));
	last if $hash;
	sleep 1;
      }
      if (!$hash) {
	warn "store_block failed after 4 attempts: " . $self->{whc}->errstr;
	return undef;
      }

      if ($self->{write_hint_keep})
      {
	my $keephash = $self->{whc}->store_in_keep (hash => $hash);
	$hash = $keephash if $keephash;
      }

      push @{$self->{myhashes}}, $hash;
    }
    substr $self->{write_buf}, 0, $writesize, "";
  }

  return $self->_finish_async_writes (0) if ($flushall);
  return 1;
}

sub _finish_async_writes
{
  my $self = shift;
  my $wantmax = shift;
  my $ok = 1;
  for (my $i = 0; $i <= $#{$self->{myhashes}}; $i++)
  {
    return $ok if ($self->{async_writes} <= $wantmax ||
		   $self->{async_writes} == 0);

    if (ref $self->{myhashes}->[$i])
    {
      printf STDERR ("child %d read\n",
		     $self->{myhashes}->[$i]->{pid})
	  if $ENV{DEBUG_ASYNC_WRITE};

      my $r = $self->{myhashes}->[$i]->{readhandle};
      my $hash = <$r>;
      $ok = undef if !$hash;

      printf STDERR ("child %d returned %s\n",
		     $self->{myhashes}->[$i]->{pid},
		     $hash)
	  if $ENV{DEBUG_ASYNC_WRITE};

      waitpid $self->{myhashes}->[$i]->{pid}, 0;
      $ok = undef if $? != 0;

      printf STDERR ("child %d finished exit 0x%x\n",
		     $self->{myhashes}->[$i]->{pid},
		     $?)
	  if $ENV{DEBUG_ASYNC_WRITE};

      $self->{myhashes}->[$i] = $hash;

      --$self->{async_writes};
    }
  }
  return $ok;
}



=head2 write_finish

 $stream->write_finish;

Indicate that all data belonging to the current file has been written
with L</write_data>.

The data does not necessarily get stored in the warehouse until you
call L</as_string>.  (Of course, you would never be able to retrieve
it without L</as_string> anyway.)

=cut

sub write_finish
{
  my $self = shift;
  die "write_finish without matching write_start"
      if (!defined $self->{write_filename} ||
	  !defined $self->{write_filepos});

  my $filesize = $self->{write_pos} - $self->{write_filepos};
  push @{$self->{myfiles}}, join (":",
				  $self->{write_filepos},
				  $filesize,
				  $self->{write_filename});
  delete $self->{write_filename};
  delete $self->{write_filepos};
  return 1;
}



=head2 rewind

 $stream->rewind;

Go [back] to the first file/block in the stream.

=cut

sub rewind
{
  my $self = shift;
  if (defined $self->{myhashes})
  {
    $self->{nexthashes} = [@{$self->{myhashes}}];
  }
  elsif (defined $self->{subdir})
  {
    my @files;
    my @hashes;
    ($self->{name}, @files) = split (" ", $self->{subdir});
    chomp ($files[-1]) if @files;
    while (@files)
    {
      if ($files[0] =~ /^-\d+$/)
      {
	push @hashes, shift @files;
	push @hashes, shift @files;
      }
      elsif ($files[0] =~ /^[0-9a-f]{32}([-\+].*)?$/)
      {
	push @hashes, shift @files;
      }
      else
      {
	last;
      }
    }
    $self->{nexthashes} = \@hashes;
    $self->{nextfiles} = \@files;
  }
}



=head2 file_next

 $stream->rewind;
 while (my ($pos, $size, $filename) = $stream->file_next)
 {
   last if !defined $pos;
   $stream->seek ($pos);
   while (my $dataref = $stream->read_until ($pos + $size))
   {
     # process data ($$dataref) from file ($filename)
   }
 }

=cut

sub file_next
{
  my $self = shift;
  if (@{$self->{nextfiles}} == 0)
  {
    return undef;
  }
  return split (":", shift @{$self->{nextfiles}}, 3);
}



=head2 seek

    $stream->seek ($pos);

Seeks forward to $pos bytes from the beginning of the stream.  Dies on
failure (eg. stream not long enough, or already past $pos).

=cut

sub seek
{
    my $self = shift;
    my $pos = shift;

    my $sizehint;
    while (@{$self->{nexthashes}} &&
	   ($self->{nexthashes}->[0] =~ /^([0-9a-f]{32})?.*?\+GS()(\d+)/ ||
	    $self->{nexthashes}->[0] =~ /^([0-9a-f]{32})?([-\+])(\d+)/) &&
	   $pos >= ($self->{bufpos}
		    + ($sizehint = ($2 eq '-'
				    ? $Warehouse::blocksize - $3
				    : $3))
		    + length $self->{buf}))
    {
	shift @{$self->{nexthashes}};
	shift @{$self->{nexthashes}} if !defined $1;
	$self->{bufpos} += length $self->{buf};
	$self->{bufpos} += $sizehint;
	$self->{buf} = "";
	$self->{bufcursor} = 0;
    }
    while ($pos > $self->{bufpos} + length $self->{buf}
	   && @{$self->{nexthashes}})
    {
	# skip "blockshortness" token
	shift @{$self->{nexthashes}} if $self->{nexthashes}->[0] =~ /^-\d+$/;

	# seek past stuff in current buffer, if any, and read next block
	$self->{bufpos} += length $self->{buf};
	$self->{buf} = $self->{whc}->fetch_block (shift @{$self->{nexthashes}})
	    or die "fetch_block failed";
	$self->{bufcursor} = 0;

	# this loop should only run once if size hints are present
    }
    if ($pos > $self->{bufpos}
	&& $pos <= $self->{bufpos} + length $self->{buf})
    {
	$self->{bufcursor} = $pos - $self->{bufpos};
    }
    if ($pos != $self->{bufpos} + $self->{bufcursor})
    {
	die "Internal error: sought $pos but at ".($self->{bufpos} + $self->{bufcursor});
    }
}



=head2 read_until

    while (my $dataref = $stream->read_until ($endpos))
    {
	print $$dataref;
    }

    while (my $dataref = $stream->read_until ($endpos, "\n"))
    {
	print $$dataref;
    }

    while (my $dataref = $stream->read_until (undef, "\n"))
    {
	print $$dataref;
    }

Read data from stream until position $endpos is reached, or until the
given end-of-record delimiter is reached.

If a delimiter is specified, then either $$dataref will end with the
delimiter, or it will contain all data up to $endpos.

If a delimiter is not specified, and $endpos has not already been
reached, then $$dataref will have some data; but it will not
necessarily contain all data up to $endpos.

=cut

sub read_until
{
  my $self = shift;
  my $endpos = shift;		# do not read past $endpos
  my $delimiter = shift;	# read up to and including the next occurrence of $delimiter, or to $endpos if none

  # we have:
  # $self->{buf} = some data from the stream
  # $self->{bufpos} = where in the stream the first byte of $self->{buf} came from
  # $self->{bufcursor} = where in $self->{buf} the client will get its next byte from
  # $wantbytes = how long $self->{buf} should be in order to satisfy this request

  my $wantbytes = (defined ($endpos)
		   ? $endpos - $self->{bufpos}
		   : 2 * $Warehouse::blocksize);
  if ($wantbytes < $self->{bufcursor})
  {
    die "read_until endpos $endpos < current pos ".($self->{bufpos} + $self->{bufcursor});
  }
  if ($wantbytes == $self->{bufcursor})	# already at end of file
  {
    return undef;
  }
  my $dpos;
  while ($self->{bufcursor} == length $self->{buf}
	 ||
	 (defined $delimiter
	  && 0 > ($dpos = index $self->{buf}, $delimiter, $self->{bufcursor}) # no delimiter yet after bufcursor
	  && $wantbytes > length $self->{buf})) # haven't reached end of this file yet
  {
    # maybe we reach the end of the stream without finding a $delimiter
    last if !@{$self->{nexthashes}};

    # maybe we found $delimiter in buf, but it's beyond $endpos
    last if defined $dpos && $dpos > $wantbytes - length $delimiter;

    if ($self->{bufcursor} > 0)
    {
      $self->{buf} = substr $self->{buf}, $self->{bufcursor};
      $wantbytes -= $self->{bufcursor};
      $self->{bufpos} += $self->{bufcursor};
      $self->{bufcursor} = 0;
    }

    # skip "blockshortness" token
    shift @{$self->{nexthashes}} if $self->{nexthashes}->[0] =~ /^-\d+$/;

    my $nexthash = shift @{$self->{nexthashes}};
    my $dataref = $self->{whc}->fetch_block_ref ($nexthash)
	or die "fetch_block_ref($nexthash) failed";
    $self->{buf} .= $$dataref;

    $dpos = undef;
  }
  if (defined $dpos &&
      $dpos >= 0 &&
      $wantbytes > $dpos + length $delimiter) # only need bytes up to end of delimiter
  {
    $wantbytes = $dpos + length $delimiter;
  }
  if ($wantbytes > length $self->{buf})	# can only have bytes up to end of buf, even if more requested
  {
    $wantbytes = length $self->{buf};
  }
  if ($wantbytes <= $self->{bufcursor})
  {
    return undef;
  }
  $self->{clientbuf} = substr $self->{buf}, $self->{bufcursor}, $wantbytes - $self->{bufcursor};
  $self->{bufcursor} = $wantbytes;

  if ($self->{bufcursor} == length $self->{buf})
  {
    # convenient time to free up some memory
    $self->{buf} = "";
    $self->{bufpos} += $self->{bufcursor};
    $self->{bufcursor} = 0;
  }
  
  return \$self->{clientbuf};
}



=head2 tell

    my $currentpos = $stream->tell;

=cut

sub tell
{
    my $self = shift;
    return $self->{bufpos} + $self->{bufcursor};
}



=head2 errstr

    warn $stream->errstr;

=cut

sub errstr
{
  my $self = shift;
  return $self->{whc}->errstr;
}

1;

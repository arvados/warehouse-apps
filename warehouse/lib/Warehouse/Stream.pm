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
  $self->{buf} = "";
  $self->rewind;
  return $self;
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
    return $self->{subdir};
  }

  if (exists $self->{write_buf})
  {
    $self->_write_flush (1) or die "_write_flush failed";

    die "as_string called while still writing ".$self->{write_filename}
	if exists $self->{write_filename};

    return join (" ",
		 $self->name,
		 @{$self->{myhashes}},
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
    $self->_write_flush (1) or die "_write_flush failed";

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
      if (!defined $self->{write_filename} ||
	  !defined $self->{write_filepos});
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

    my $hash = $self->{whc}->store_block (substr ($self->{write_buf},
						  0, $writesize));
    if (!$hash)
    {
      return undef;
    }

    my $sizehint =
	$Warehouse::blocksize == $writesize
	? "-0"
	: "+".$writesize;
    push @{$self->{myhashes}}, $hash.$sizehint;
    substr $self->{write_buf}, 0, $writesize, "";
  }
  return 1;
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
      elsif ($files[0] =~ /^[0-9a-f]{32}([-\+]\d+)?$/)
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
	   $self->{nexthashes}->[0] =~ /^([0-9a-f]{32})?([-\+])(\d+)$/ &&
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

	# this loop should only run once if size hints are present
    }
    if ($pos > $self->{bufpos}
	&& $pos <= $self->{bufpos} + length $self->{buf})
    {
	substr ($self->{buf}, 0, $pos - $self->{bufpos}) = "";
	$self->{bufpos} = $pos;
    }
    if ($pos != $self->{bufpos})
    {
	die "Internal error: sought $pos but at ".$self->{bufpos};
    }
}



=head2 read_until

    while (my $dataref = $stream->read_until ($endpos))
    {
	print $$dataref;
    }

Read data from stream until position $endpos is reached.

=cut

sub read_until
{
    my $self = shift;
    my $endpos = shift;
    my $wantbytes = $endpos - $self->{bufpos};
    if ($wantbytes < 0)
    {
	die "read_until endpos $endpos < current pos ".$self->{bufpos};
    }
    if ($wantbytes == 0)
    {
	return undef;
    }
    if (0 == length $self->{buf})
    {
	# skip "blockshortness" token
	shift @{$self->{nexthashes}} if $self->{nexthashes}->[0] =~ /^-\d+$/;

	$self->{buf} = $self->{whc}->fetch_block (shift @{$self->{nexthashes}})
	    or die "fetch_block failed";
    }
    if ($wantbytes > length $self->{buf})
    {
	$wantbytes = length $self->{buf};
    }
    my $wantdata = substr ($self->{buf}, 0, $wantbytes);

    substr ($self->{buf}, 0, $wantbytes) = "";
    $self->{bufpos} += $wantbytes;

    return \$wantdata;
}



=head2 tell

    my $currentpos = $stream->tell;

=cut

sub tell
{
    my $self = shift;
    return $self->{bufpos};
}

1;

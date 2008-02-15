# -*- mode: perl; perl-indent-level: 4; -*-

package Warehouse::Manifest;

use Warehouse;

=head1 NAME

Warehouse::Manifest -- API for working with warehouse manifests, aka
lists of subdirectories, files, and contents

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use Warehouse::Manifest;

 my $manifest = Warehouse::Manifest->new (whc => $whc);
 my $manifest = Warehouse::Manifest->new (whc => $whc,
					  key => $key);
 my $manifest = Warehouse::Manifest->new (whc => $whc,
					  data => \$manifestdata);

 my $file_data_ref = $manifest->get_file_data ($filename)
  or die $manifest->errstr;

 $manifest->set_file_data ($filename, \$file_data)
  or die $manifest->errstr;

 my $key = $manifest->write
  or die $manifest->errstr;

 my $manifestdata = $manifest->data;

=head1 METHODS

=head2 new

    my $manifest = Warehouse::Manifest->new (whc => $whc,
					     key => $manifestkey);

Creates a new manifest.  Returns the new object on success.  Dies on
failure.

If scalar "key" is provided, data is retrieved from warehouse.

If scalarref "data" is provided, it is taken as the plain text
manifest.

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
    my Warehouse::Manifest $self = shift;
    $self->{whc} or die "Manifest->new: whc not specified";
    if ($self->{key})
    {
	my $data = join ("",
			 map {
			   $self->{whc}->fetch_block ($_) or die $self->{whc}->errstr
			     }
			 split (",", $self->{key}));
	$self->{data} = \$data;
	$self->rewind;
    }
    return $self;
}



=head2 get_file_data

    my $file_data_ref = $manifest->get_file_data ($filename);

Returns the contents of the named file in a scalarref.  Returns undef,
and makes an error message available via errstr, if the file cannot be
retrieved.

=cut

sub get_file_data
{
    my $self = shift;
    my ($stream, $pos, $size) = $self->get_file_data_as_stream (@_);
    return undef if !$stream;

    my $data = "";
    $stream->seek ($pos);
    while (my $dataref = $stream->read_until ($pos+$size))
    {
	$data .= $$dataref;
    }
    return \$data;
}



sub write
{
    my $self = shift;
    $self->{whc}->write_start ("directory") or return undef;
    $self->{whc}->write_data ($self->{data}) or return undef;
    my $key = $self->{whc}->write_finish or return undef;
    return $key;
}



sub rewind
{
  my $self = shift;
  $self->{subdir_datapos} = 0;
}



sub subdir_next
{
  use Warehouse::Stream;
  my $self = shift;
  die "subdir_next called without subdir_rewind"
      if !defined $self->{subdir_datapos};
  my $nextnewline = index $ {$self->{data}}, "\n", $self->{subdir_datapos};
  if ($nextnewline < 0)
  {
    return undef;
  }
  my $s = new Warehouse::Stream
      (whc => $self->{whc},
       subdir => substr ($ {$self->{data}},
			 $self->{subdir_datapos},
			 $nextnewline - $self->{subdir_datapos}));
  $self->{subdir_datapos} = $nextnewline + 1;
  return $s;
}



sub get_file_data_as_stream
{
    my $self = shift;
    my $filename = shift;

    my ($wantsubdir, $wantfile) = $filename =~ m,^(.*?)([^/]*)$,;
    $wantsubdir = "/".$wantsubdir;
    $wantsubdir =~ s,/$,,;

    foreach my $subdir (split ("\n", $ {$self->{data}}))
    {
	my @subdir = split (" ", $subdir);
	my $subdir_name = shift @subdir;

	$subdir_name =~ s/^\.//
	    or die "subdir name '$subdir_name' does not start with period";
	if ($subdir_name eq $wantsubdir)
	{
	    my @hash;
	    while (@subdir)
	    {
		if ($subdir[0] =~ /^-\d+$/)
		{
		    push @hash, splice @subdir, 0, 2;
		}
		elsif ($subdir[0] =~ /^[0-9a-f]{32}[-\+]?/)
		{
		    push @hash, shift @subdir;
		}
		else
		{
		    last;
		}
	    }
	    foreach (@subdir)
	    {
		if (/^(\d+):(\d+):\Q$wantfile\E$/)
		{
		    my ($pos, $size) = ($1, $2);
		    my $stream = new Warehouse::Stream (whc => $self->{whc},
							hash => \@hash);
		    return ($stream, $pos, $size);
		}
	    }
	}
    }
    $self->{errstr} = "file not found";
    return undef;
}



sub errstr
{
    my $self = shift;
    return $self->{errstr};
}



=head1 MANIFEST FORMAT

 manifest := subdir subdir subdir ...

 subdir := subdirname <space> stream <newline>

 subdirname := <period>
            or <period> <slash> string (not ending with slash)

 stream := blocklist <space> filelist

 blocklist := block block block ...

 block := blockshortness <space> md5sum (deprecated)
       or md5sum blockshortness hint hint ... (deprecated)
       or md5sum plusblocklength hint hint ...
       or md5sum hint hint ...
       or md5sum

 blockshortness := -0 (meaning the block is 2^26 bytes long)
		or -N (meaning the block is 2^26 - N bytes long)

 plusblocklength := +N (meaning the block is N bytes long)

 hint := + K keepbitvector @ warehousename
      or + ... (other kinds of hints yet to be defined)

 keepbitvector := little-endian hex representation: if bit P is on,
                  the block is stored on the warehouse named
                  "warehousename", on the node which appears at
                  position P in the probe order for md5sum (eg. if
                  probe order is 6,34,1,9,12,22,21,44 and
                  keepbitvector "03" signifies nodes 6 and 34;
                  keepbitvector "06" signifies nodes 34 and 9;
                  keepbitvector "81" signifies nodes 6 and 44)

 md5sum := [0-9a-f]{32}

 filelist := file file file ...

 file := position <colon> size <colon> name

 position := decimal number of bytes from start of stream to beginning
             of this file's data

 size := decimal number of bytes

=head2 Example

 . b739bca6df51d8c189de04e59571f09b+1666 0:1666:INSTALL
 ./subdir1 2da5e40fa3dbb2531da9713144d2070b-0 f0766d92a869fcaeb765c18ca9eabef9+38108802 0:1666:INSTALL 1666:105216000:slurm-1.2.19.tar

Note:

  2^26 + 38108802 = 105217666
 1666 + 105216000 = 105217666

=head2 Example (deprecated)

 . -67107198 b739bca6df51d8c189de04e59571f09b 0:1666:INSTALL
 ./subdir1 -0 2da5e40fa3dbb2531da9713144d2070b -29000062 f0766d92a869fcaeb765c18ca9eabef9 0:1666:INSTALL 1666:105216000:slurm-1.2.19.tar

Note:

 2^26 - 0 + 2^26 - 29000062 = 105217666
           1666 + 105216000 = 105217666

=cut

1;

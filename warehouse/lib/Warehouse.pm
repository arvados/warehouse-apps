# -*- mode: perl; perl-indent-level: 4; -*-

package Warehouse;

use Digest::MD5;
use MogileFS::Client;
use Cache::Memcached;
use LWP::UserAgent;
use HTTP::Request::Common;
use Date::Parse;
use IO::Handle;
use Warehouse::Stream;

$memcached_max_data = 1000000;
$no_warehouse_client_conf = 0;
$no_memcached_conf = 0;

do '/etc/warehouse/warehouse-client.conf'
    or $no_warehouse_client_conf = 1;
do '/etc/warehouse/memcached.conf.pl'
    or $no_memcached_conf = 1;

$ENV{NOCACHE_READ} = 1 if $ENV{NOCACHE};
$ENV{NOCACHE_WRITE} = 1 if $ENV{NOCACHE};

$blocksize ||= 2**26;
$svn_root ||= "http://dev.freelogy.org/svn/polony/polony-tools/trunk";

=head1 NAME

Warehouse -- Client library for the storage warehouse.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use Warehouse;

 my $whc = Warehouse->new;

 my $sample_content = "some binary data";

 # Store data
 my $filehash = $whc->store_block ($sample_content)
     or die "write failed: ".$whc->errstr;

 # Store a [possibly >64MiB] file into multiple blocks
 $whc->write_start or die "Write failed";
 while(<>) {
     $whc->write_data ($_) or die "Write failed";
 }
 my @filehashes = $whc->write_finish or die "Write failed";

 # Retrieve data
 my $content = $whc->fetch_block ($filehash);

 # Retrieve data without verifying hash($content)==$filehash
 my $content = $whc->fetch_block ($filehash, 0);

 # Give a manifest a name in the warehouse
 $whc->store_manifest_by_name ($newkey, $oldkey, $name)
     or die "update failed";

 # Retrieve key of a named manifest
 my $key = $whc->fetch_manifest_key_by_name ($name);

 # Get a list of mapreduce jobs
 my $joblist = $whc->job_list;
 my $joblist = $whc->job_list (id_min => 123, id_max => 345);
 print map { "job ".$_->{id}." was a ".$_->{mrfunction}.".\n" } @$joblist;

 # Submit a mapreduce job
 my $jobid = $whc->job_new (mrfunction => "zmd5", ...);

=head1 METHODS

=head2 new

 my $whc = Warehouse->new( %OPTIONS );

Creates a new Warehouse object.  Returns the new object on success.
Dies on failure.

=head3 Options

=over

=item warehouse_name

Name of a warehouse configured in /etc/warehouse/warehouse-client.conf

=item warehouse_servers

Comma-separted list of warehouse servers: host:port,host:port,...
Comes from warehouse-client.conf if not specified.

=item memcached_servers

Memcached servers (arrayref; see Cache::Memcached(3)).  Comes from
memcached.conf.pl if not specified.

=item mogilefs_trackers

Comma-separated list of MogileFS tracker hosts.  Comes from
warehouse-client.conf if not specified.

=item mogilefs_domain

MogileFS domain.  Comes from warehouse-client.conf if not specified.

=item mogilefs_directory_class

MogileFS class used for storing directory listings.  Comes from
warehouse-client.conf if not specified.

=item mogilefs_file_class

MogileFS class used for storing files.  Comes from
warehouse-client.conf if not specified.

=item mogilefs_size_threshold

Minimum block size to store in mogilefs, in bytes.  Default is 0.  Do
not use a value greater than 1 + memcached_size_threshold.

=item memcached_size_threshold

Maximum block size to store in memcached, in bytes.  Default is
1000000.  Zero means never use memcached for data.  Negative means
never use memcached for either data or mogilefs paths.  Blocks are
stored in memcached as <= 1000000-byte chunks in any case.

=back

=cut


sub new
{
    my $class = shift;
    my $self = { @_ };
    bless ($self, $class);
    return $self->_init();
}

sub _init
{
    my Warehouse $self = shift;
    my $attempts = 0;

    die "Failed to load /etc/warehouse/warehouse-client.conf" if $no_warehouse_client_conf;

    my $warehouse_name =
	$self->{warehouse} ||
	$self->{warehouse_name} ||
	$ENV{WAREHOUSE} ||
	(ref $warehouses eq ARRAY && $warehouses->[0]->{name});

    if (!defined $warehouse_name)
    {
	die "I don't have a default warehouse to use";
    }

    my ($idx) = grep {
	$warehouses->[$_]->{name} eq $warehouse_name
    } (0..$#$warehouses)
    or die "I know no warehouse named ".$warehouse_name;

    $self->{config} = $warehouses->[$idx];
    $self->_cryptsetup();
    $self->{warehouse_index} = $idx;
    $self->{warehouse_name} = $warehouse_name;
    $self->{config}->{svn_root} ||= $svn_root;
    $self->{name_warehouse_servers} = $warehouses->[$idx]->{name_controllers};
    $self->{job_warehouse_servers} = $warehouses->[$idx]->{job_controllers};
    $self->{cryptmap_name_controllers} = $warehouses->[$idx]->{cryptmap_name_controllers};
    $self->{name_warehouse_servers} = $warehouses->[$idx]->{controllers}
	if !defined $self->{name_warehouse_servers};
    $self->{job_warehouse_servers} = $warehouses->[$idx]->{controllers}
	if !defined $self->{job_warehouse_servers};
    $self->{cryptmap_name_controllers} = $warehouses->[$idx]->{controllers}
	if !defined $self->{cryptmap_name_controllers};
    $self->{mogilefs_trackers} = $warehouses->[$idx]->{mogilefs_trackers};
    $self->{mogilefs_domain} = $warehouses->[$idx]->{mogilefs_domain};
    $self->{mogilefs_directory_class} = $warehouses->[$idx]->{mogilefs_directory_class};
    $self->{mogilefs_file_class} = $warehouses->[$idx]->{mogilefs_file_class};
    $self->{keeps} = $warehouses->[$idx]->{keeps};
    if (!defined($warehouses->[$idx]->{keep_name})) {
        $self->{keep_name} = $self->{warehouse_name};
    } else {
        $self->{keep_name} = $warehouses->[$idx]->{keep_name};
    }
    $self->{memcached_size_threshold} = 0 if $idx != 0;
    $self->{memcached_size_threshold} = -1 if $no_memcached_conf;

    $self->{name_warehouse_servers} = $warehouse_servers
	if !defined $self->{name_warehouse_servers};
    $self->{job_warehouse_servers} = $warehouse_servers
	if !defined $self->{job_warehouse_servers};

    $self->{memcached_size_threshold} = $memcached_max_data
	if !defined $self->{memcached_size_threshold};

    $self->{memcached_servers} = $memcached_servers_arrayref
	if !defined $self->{memcached_servers};

    $self->{mogilefs_trackers} = $mogilefs_trackers
	if !defined $self->{mogilefs_trackers};

    $self->{mogilefs_domain} = $mogilefs_domain
	if !defined $self->{mogilefs_domain};

    $self->{mogilefs_directory_class} = $mogilefs_directory_class
	if !defined $self->{mogilefs_directory_class};

    $self->{mogilefs_file_class} = $mogilefs_file_class
	if !defined $self->{mogilefs_file_class};

    $self->{mogilefs_size_threshold} = 0
	if !defined $self->{mogilefs_size_threshold};

    $self->{debug_mogilefs_paths} = 0
	if !defined $self->{debug_mogilefs_paths};

    $self->{timeout} = 10
	if !defined $self->{timeout};

    $self->{rand01} = int(rand 2);

    $self->{stats_time_created} = time;
    $self->{stats_read_bytes} = 0;
    $self->{stats_read_blocks} = 0;
    $self->{stats_read_attempts} = 0;
    $self->{stats_wrote_bytes} = 0;
    $self->{stats_wrote_blocks} = 0;
    $self->{stats_wrote_attempts} = 0;
    $self->{stats_memread_bytes} = 0;
    $self->{stats_memread_blocks} = 0;
    $self->{stats_memread_attempts} = 0;
    $self->{stats_memwrote_bytes} = 0;
    $self->{stats_memwrote_blocks} = 0;
    $self->{stats_memwrote_attempts} = 0;
    $self->{stats_keepread_bytes} = 0;
    $self->{stats_keepread_blocks} = 0;
    $self->{stats_keepread_attempts} = 0;
    $self->{stats_keepwrote_bytes} = 0;
    $self->{stats_keepwrote_blocks} = 0;
    $self->{stats_keepwrote_attempts} = 0;

    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->timeout ($self->{timeout});

    if (!$ENV{NOCACHE_READ} || !$ENV{NOCACHE_WRITE})
    {
	while (!$self->{mogc} && ++$attempts <= 5)
	{
	    $self->{mogc} = eval {
		MogileFS::Client->new
		    (hosts => [split(",", $self->{mogilefs_trackers})],
		     domain => $self->{mogilefs_domain},
		     timeout => $self->{timeout});
	      };
	    last if $self->{mogc};
	    print STDERR "MogileFS connect failure #$attempts: $@\n";
		sleep $attempts;
	}
	die "Can't connect to MogileFS" if !$self->{mogc};

	if (@{$self->{memcached_servers}} &&
	    $self->{memcached_size_threshold} >= 0)
	{
	    $self->{memc} = new Cache::Memcached {
		'servers' => $self->{memcached_servers},
		'debug' => 0,
	    };
	    $self->{memc}->enable_compress (0);
	}

	if ($self->{memcached_size_threshold} + 1
	    < $self->{mogilefs_size_threshold})
	{
	    warn("Warehouse: Blocks with "
		 .$self->{memcached_size_threshold}
		 ." < size < "
		 .$self->{mogilefs_size_threshold}
		 ." will not be stored in either memcached or mogilefs!\n");
	}
    }

    $self->{job_hashref} = {};
    $self->{manifest_stats_hashref} = {};
    $self->{meta_stats_hashref} = {};
    $self->{job_list_arrayref} = undef;
    $self->{job_list_fetched} = undef;

    return $self;
}



sub get_config
{
    my $self = shift;
    my $configvar = shift;
    return $self->{config}->{$configvar};
}



=head2 store_block

 my $hash = $whc->store_block ($data)

Store a <= 64MiB chunk of data.  On success, returns a hash which can
be used to retrieve the data.  On failure, returns undef.

=cut


sub store_block
{
    my $self = shift;
    my $dataarg = shift;
    my $dataref = ref $dataarg ? $dataarg : \$dataarg;

    if ($ENV{NOCACHE_WRITE} || $ENV{NOCACHE})
    {
	return scalar $self->store_in_keep (dataref => $dataref,
					    nnodes => 2);
    }

    my $mogilefs_class = shift || $self->{mogilefs_file_class};
    my $md5 = Digest::MD5::md5_hex ($$dataref);
    my $size = length $$dataref;
    my $hash = "$md5+$size";

    my $alreadyhave;
    $alreadyhave = $self->fetch_block_ref ($hash, 1, 1)
	if !$ENV{NOPLAIN};
    if ($alreadyhave && $$dataref eq $$alreadyhave)
    {
	return $hash;
    }
    if (my $alreadyhavehash = $self->_cryptmap_fetchable ($dataref, $hash))
    {
	return $alreadyhavehash;
    }

    if (@{$self->{config}->{encrypt}})
    {
	my $enc = $self->_encrypt_block ($dataref);
	die "Encrypted data is the same as original data"
	    if $$dataref eq $$enc;

	my $dec = $self->_decrypt_block ($enc);
	die "Encrypted data but was not able to decrypt it"
	    if $$dec ne $$dataref;

	my $md5_enc = Digest::MD5::md5_hex ($$enc);
	my $hash_enc = sprintf ("%s+%d+GS%d+GM%s",
				$md5_enc,
				length $$enc,
				length $$dataref,
				$md5);

	$self->_cryptmap_write ($hash, $hash_enc);
	$md5 = $md5_enc;
	$hash = $hash_enc;
	$dataref = $enc;
    }

    if ($size <= $self->{memcached_size_threshold}
	&& !$ENV{NOCACHE}
	&& !$ENV{NOCACHE_WRITE})
    {
	$self->_store_block_memcached ($md5, $dataref);
    }

    if ($size >= $self->{mogilefs_size_threshold})
    {
	eval
	{
	    $self->_mogilefs_write ($md5, $dataref, $mogilefs_class);
	}
	or eval
	{
	    $self->_mogilefs_write ($md5, $dataref, $mogilefs_class);
	}
	or do
	{
	    $self->{errstr} = $@;
	    return scalar $self->store_in_keep (dataref => $dataref,
						nnodes => 2);
	}
    }

    return $hash;
}


sub _store_block_memcached
{
    my $self = shift;
    my $md5 = shift;
    my $dataref = shift;

    for (my $chunk = 0;
	 $chunk * $memcached_max_data < length $$dataref;
	 $chunk ++)
    {
	$self->{stats_memwrote_attempts} ++;
	$self->{stats_memwrote_blocks} ++;
	my $frag = substr ($$dataref,
			   $chunk * $memcached_max_data,
			   $memcached_max_data);
	$self->{memc}->set ($md5.".".$chunk, $frag);

	warn "set ${hash}.${chunk} => ".(length $frag)."\n"
	    if $self->{debug_memcached};
    }
    $self->{stats_memwrote_bytes} += length $$dataref;
}



sub _mogilefs_write
{
    my $self = shift;
    my $md5 = shift;
    my $dataref = shift;
    my $class = shift;
    $self->{stats_wrote_attempts} ++;
    my $mogfh = $self->{mogc}->new_file ($md5, $class);
    if (!$mogfh)
    {
	$mogfh = $self->{mogc}->new_file ($md5, $class);
    }
    if (!$mogfh)
    {
	die "MogileFS new_file failed: ".$self->{mogc}->errstr;
    }
    if (!print $mogfh $$dataref)
    {
	close $mogfh;
	die "MogileFS write failed: $!";
    }
    if (!close $mogfh)
    {
	die "MogileFS write failed: $!";
    }
    $self->{stats_wrote_bytes} += length $$dataref;
    $self->{stats_wrote_blocks} ++;
    1;
}



=head2 write_start

 $whc->write_start;

Prepares to store a file (possibly more than 64M bytes) in the
warehouse.  Analogous to open(2).

=cut


sub write_start
{
    my $self = shift;
    my $is_directory = shift;
    $self->{output_buffer} = "";
    $self->{hashes_written} = [];
    $self->{write_class} = ($is_directory
			    ? $self->{mogilefs_directory_class}
			    : $self->{mogilefs_file_class});
    1;
}


=head2 write_data

 $whc->write_data ($data) or die "Write failed.";

Appends some data to a file in the warehouse.  Analogous to write(2).
Returns true on success.  Returns undef on failure.

=cut


sub write_data
{
    my $self = shift;
    my $data_arg = shift;
    my $dataref = ref $data_arg ? $data_arg : \$data_arg;
    $self->{output_buffer} .= $$dataref;
    while (length ($self->{output_buffer}) >= $blocksize)
    {
	my $hash = $self->store_block (substr ($self->{output_buffer},
					       0, $blocksize),
				       $self->{write_class});
	if (!$hash)
	{
	    return undef;
	}
	push @{$self->{hashes_written}}, $hash;
	substr ($self->{output_buffer}, 0, $blocksize) = "";
    }
    1;
}


=head2 write_finish

 my @hashes = $whc->write_finish or die "Write failed";

Writes to disk all remaining data from previous write_data() calls.
Analogous to close(2).  Returns a list of hashes on success.  Returns
undef on failure.

=cut


sub write_finish
{
    my $self = shift;
    if (length ($self->{output_buffer}) > 0)
    {
	my $hash = $self->store_block ($self->{output_buffer},
				       $self->{write_class});
	if (!$hash)
	{
	    return undef;
	}
	push @{$self->{hashes_written}}, $hash;
	$self->{output_buffer} = "";
    }
    if (wantarray)
    {
      return @{$self->{hashes_written}};
    }
    else
    {
      # return hash list as a manifest key (comma-separated, without
      # block size hints)
      return join (",",
		   map {
		     /^(-\d+ )?([0-9a-f]{32})/;
		     $2;
		   } @{$self->{hashes_written}});
    }
}


=head2 fetch_block

 foreach my $hash (@hashes)
 {
     my $data = $whc->fetch_block ($hash) or die "Read failed";
     print $data;
 }

Retrieves content previously stored using L</store_block> or
L</write_data>.  Returns binary data on success.  Returns undef on
failure.

=cut


sub fetch_block
{
    my $self = shift;
    my $r = $self->fetch_block_ref (@_);
    return undef if !defined $r;
    return $$r;
}


sub fetch_block_ref
{
    my $self = shift;
    my $hash = shift;
    my $verifyflag = ref $_[0] ? undef : shift;
    my $nowarnflag = ref $_[0] ? undef : shift;
    my $options = @_ ? shift : {};

    $verifyflag = $options->{verify} if !defined $verifyflag;
    $verifyflag = 1 if !defined $verifyflag;
    $nowarnflag = $options->{nowarn} if !defined $nowarnflag;

    return \qq{} if $hash =~ /^d41d8cd98f00b204e9800998ecf8427e\b/;

    if ($hash =~ /\+K/ || $ENV{NOCACHE_READ} || $ENV{NOCACHE})
    {
	my $dataref = $self->fetch_from_keep
	    ($hash, { nodecrypt => $options->{nodecrypt} });
	return $dataref if $dataref || $ENV{NOCACHE_READ} || $ENV{NOCACHE};
    }

    my $sizehint;
    if ($hash =~ s/^(-(\d+) )//)
    {
	$sizehint = $blocksize - $2;
    }
    elsif ($hash =~ s/-(\d+)$//)
    {
	$sizehint = $blocksize - $1;
    }
    else
    {
	my @hints;
	($hash, @hints) = split (/\+/, $hash);
	foreach (@hints)
	{
	    $sizehint = $_ if /^\d+$/;
	}
    }
    my $md5 = $hash;

    my $data;
    if ((defined $sizehint ? $sizehint : 1)
	<= $self->{memcached_size_threshold})
    {
	for (my $chunk = 0;
	     $chunk * $memcached_max_data < (defined $sizehint
					     ? $sizehint
					     : $blocksize);
	     $chunk ++)
	{
	    $self->{stats_memread_attempts} ++;
	    if (defined (my $frag = $self->{memc}->get ($md5.".".$chunk)))
	    {
		$self->{stats_memread_blocks} ++;

		if ($chunk == 0)
		{
		    $data = $frag;
		}
		else
		{
		    $data .= $frag;
		}
		last if !defined $sizehint
		    && $memcached_max_data > length $frag;
		warn "get ${hash}.${chunk} => ".(length $frag)."\n"
		    if $self->{debug_memcached};
	    }
	    else
	    {
		warn "get ${hash}.${chunk} => undef\n"
		    if $self->{debug_memcached};
		last;
	    }
	}
	$self->{stats_memread_bytes} += length $data if defined $data;
    }
    if (defined $data)
    {
	if (!$verifyflag || $md5 eq Digest::MD5::md5_hex ($data))
	{
	    return \$data if $options->{nodecrypt};
	    return $self->_decrypt_block (\$data);
	}
	for (my $chunk = 0;
	     $chunk * $memcached_max_data < (defined $sizehint
					     ? $sizehint
					     : $blocksize);
	     $chunk ++)
	{
	    $self->{memc}->delete ($md5.".".$chunk);
	}
    }

    $self->{stats_read_attempts} ++;
    my $dataref = $self->_get_file_data ($md5, $verifyflag, $options);
    if (defined $dataref)
    {
	$self->{stats_read_bytes} += length $$dataref;
	$self->{stats_read_blocks} ++;
    }

    if (!defined $dataref && $hash !~ /\+K/)
    {
	# didn't try Keep earlier, and other methods failed, so try it now
	$dataref = $self->fetch_from_keep ($hash, { nodecrypt => 1 });
	if ($dataref && ($options->{offset} || exists $options->{length}))
	{
	    if (!exists $options->{nodecrypt})
	    {
		$dataref = $self->_decrypt_block ($dataref)
		    or die "failed to decrypt data: cannot satisfy partial block request";
	    }
	    $$dataref = substr ($$dataref,
				$options->{offset} || 0,
				$options->{length});
	    return $dataref;
	}
    }

    if (!defined $dataref)
    {
	warn "fetch_block_ref($md5) failed: ".$self->{errstr}
	    unless $nowarnflag;
    }

    if ($dataref
	&& length $$dataref <= $self->{memcached_size_threshold}
	&& !exists $options->{length}
	&& !$options->{offset})
    {
	$self->_store_block_memcached ($md5, $dataref);
    }

    return undef if !$dataref;
    return $dataref if $options->{nodecrypt};
    return $self->_decrypt_block ($dataref);
}



=head2 store_in_keep

 my $hash = $whc->store_block ("foo");
 my ($hash_with_hints, $nnodes) = $whc->store_in_keep (hash => $hash,
						       nnodes => 2);
 my $data = "bar";
 my ($hash_with_hints, $nnodes) = $whc->store_in_keep (dataref => \$data,
						       nnodes => 2);

=cut


sub store_in_keep
{
    my $self = shift;
    my %arg = @_;
    my $dataref = $arg{dataref};
    my ($md5, @hints);
    if ($arg{hash} =~ /,/)
    {
	my @hash;
	my $min_nnodes;
	foreach (split (/,/, $arg{hash}))
	{
	    $arg{hash} = $_;
	    my ($hash, $nnodes) = $self->store_in_keep (%arg);
	    return undef if !$nnodes;
	    push @hash, $hash;
	    $min_nnodes = $nnodes
		if !defined $min_nnodes || $min_nnodes > $nnodes;
	}
	my $hashes = join (",", @hash);
	return $hashes if !wantarray;
	return ($hashes, $min_nnodes);
    }
    if (exists $arg{hash})
    {
	($md5, @hints) = split (/[-\+]/, $arg{hash});
    }
    elsif (defined ($dataref))
    {
	$md5 = Digest::MD5::md5_hex ($$dataref);
	@hints = length($$dataref);
	if (@ { $self->{config}->{encrypt} })
	{
	    my ($enchash, $encdataref)
		= $self->_cryptmap_fetchable ($dataref, "$md5+$hints[0]");
	    if ($enchash)
	    {
		($md5, @hints) = split (/\+/, $enchash);
		$dataref = $encdataref;
	    }
	    else
	    {
		$dataref = $self->_encrypt_block ($dataref);
		my $encmd5 = Digest::MD5::md5_hex ($$dataref);
		my $encsize = length $$dataref;
		$self->_cryptmap_write ("$md5+$hints[0]", "$encmd5+$encsize");
		($md5, @hints) = ($encmd5, $encsize, "GS".$hints[0], "GM".$md5);
	    }
	}
    }
    $arg{nnodes} ||= 1;

    my $reqtext = time . " " . $md5;
    my $signedreq = $self->_sign ($reqtext);
    $signedreq .= $$dataref if $dataref;

    my $keepreportedsize;
    my $bits = "";
    my $nnodes = 0;
    my ($keeps, @bucket) = $self->_hash_keeps (undef, $md5);
    foreach my $bucket (0..$#bucket)
    {
	last if $bucket > 7;
	my $keep_id = $bucket[$bucket];
	$self->{stats_keepwrote_attempts} ++;
	my $keep_host_port = $keeps->[$keep_id];
	my $url = "http://".$keep_host_port."/".$md5;
	my $req = HTTP::Request->new (PUT => $url);
	$req->header ('Content-Length' => length $signedreq);
	$req->content ($signedreq);

	my $r = $self->{ua}->request ($req);
	if ($ENV{DEBUG_KEEP})
	{
	    printf STDERR ("bucket %d %s %d %s\n",
			   $bucket, $keep_host_port,
			   $r->is_success, $r->status_line);
	}
	if ($r->is_success)
	{
	    $self->{stats_keepwrote_blocks} ++;
	    $self->{stats_keepwrote_bytes} += length $signedreq;
	    $keepreportedsize ||= $r->header ("X-Block-Size");
	    vec ($bits, $bucket, 1) = 1;
	    ++ $nnodes;
	    last if $nnodes == $arg{nnodes};
	}
	else
	{
	    $self->{errstr} = $r->status_line;
	}
    }
    if (!$nnodes)
    {
	return undef;
    }
    my $hash = $md5;
    $hash .= "+$keepreportedsize" if defined $keepreportedsize;
    foreach (@hints)
    {
	$_ = 67108864 if $_ eq "0";
	next if !/\D/ && defined $keepreportedsize;
	next if /^K.*\@(.*)/ && $1 eq $self->{keep_name};
	$hash .= "+$_";
    }
    $hash .= "+K".unpack("H*", $bits)."\@".$self->{keep_name};
    return $hash if !wantarray;
    return ($hash, $nnodes);
}



=head2 fetch_from_keep

 my $dataref = $whc->fetch_from_keep ($hash);
 die "could not fetch $hash from keep" if !defined $dataref;

 my $dataref = $whc->fetch_from_keep ($hash, { nnodes => 3 });
 die "could not verify $hash on 3 different nodes" if !defined $dataref;

=cut


sub fetch_from_keep
{
    my $self = shift;
    my $hash = shift;
    my $opts = shift || {};

    my ($md5, @hints);
    ($md5, @hints) = split (/[-\+]/, $hash);

    return \qq{} if $md5 eq "d41d8cd98f00b204e9800998ecf8427e";

    my ($kbits, $kwhid);
    foreach (@hints)
    {
	if (/^K([0-9a-f]+)(?:\@(\w+))$/)
	{
	    $kbits = pack ("H*", $1);
	    map { $kwhid = $_ if $2 eq $warehouses->[$_]->{name} }
		(0..$#$warehouses);
	    last;
	}
    }
    my ($keeps, @bucket) = $self->_hash_keeps ($kwhid, $md5);
    if (defined $kbits)
    {
	my $inserthere = 0;
	for (0..$#bucket)
	{
	    splice @bucket, $inserthere++, 0, (splice @bucket, $_, 1)
		if vec($kbits, $_, 1);
	}
    }
    my $successes = 0;
    foreach my $keep_id (@bucket)
    {
	$self->{stats_keepread_attempts} ++;
	my $keep_host_port = $keeps->[$keep_id];
	my $url = "http://".$keep_host_port."/".$md5;
	my $req = HTTP::Request->new (GET => $url);
	my $r = $self->{ua}->request ($req);
	if ($r->is_success)
	{
	    my $data = $r->content;
	    my $datasize = length $data;
	    if (Digest::MD5::md5_hex ($data) eq $md5)
	    {
		warn "Keep read $keep_host_port $md5 $datasize\n"
		    if $ENV{DEBUG_KEEP};
		$self->{stats_keepread_blocks} ++;
		$self->{stats_keepread_bytes} += $datasize;
		++$successes;
		$data = $ { $self->_decrypt_block (\$data) }
		    unless $opts->{nodecrypt};
		return \$data if !$opts->{nnodes};
		return \$data if $successes == $opts->{nnodes};
	    }
	    else
	    {
		my $b = length $data;
		warn "Checksum failed fetching $keep_host_port/$md5 ($b)\n";
	    }
	}
	else
	{
	    $self->{errstr} = $r->status_line;
	}
    }
    return undef;
}


=head2 _hash_keeps

 ($keeps_arrayref, @probeorder) = $self->_hash_keeps($warehouse_id, $hash);

Return an array of all keepd servers ("host:port") in $keeps_arrayref,
and a list of indexes into that array representing the order in which
they should be attempted when storing $hash.

=cut


sub _hash_keeps
{
    my $self = shift;
    my $warehouse_id = shift;
    my $hash = shift;

    my $keeps = $self->{keeps};
    $warehouse_id = 0 if !$keeps && !defined $warehouse_id;
    $keeps = $warehouses->[$warehouse_id]->{keeps} if defined $warehouse_id;

    map { s{$}{:25107} unless m{:} } @$keeps;

    return ($keeps, 0) if $#$keeps < 1;

    my @avail = (0..$#$keeps);
    my @bucket;
    for (0..7)
    {
	# $hash ----> 0000111122223333aaaabbbbccccdddd
	# $md5bits -> 00001111 22223333 aaaabbbb ccccdddd
	#             dddd0000 11112222 3333aaaa bbbbcccc
	# $pick ----> 0x00001111 % N     1st bucket is ${pick}th node in @avail
	#             0x22223333 % (N-1) 2nd bucket is ${pick}th of what's left
	#             0xaaaabbbb % (N-2) 3rd ....
	my $md5bits = $_ < 4
	    ? substr($hash,$_*8,8)
	    : substr($hash,($_*8-4)%32,4) . substr($hash,($_*8)%32,4);
	my $pick = hex($md5bits) % (1 + $#avail);
	push @bucket, splice @avail, $pick, 1;
    }

    return ($keeps, @bucket, @avail);
}



=head2 fetch_manifest

 my $manifest = $whc->fetch_manifest ($key);

Retrieve a manifest with the given key.

Note: If the manifest is large, this is not an efficient way to read
it.  Better to fetch one block at a time.

=cut

sub fetch_manifest
{
  my $self = shift;
  my $key = shift;
  return join ("", map { $self->fetch_block ($_) } split (",", $key));
}



=head2 store_manifest_by_name

 $whc->store_manifest_by_name ($newkey, $oldkey, $name)
     or die "failed";

=cut


sub store_manifest_by_name
{
    my $self = shift;
    my ($newkey, $oldkey, $name) = @_;

    if (!defined $oldkey)
    {
	$oldkey = "NULL";
    }
    my $reqtext = "$newkey $oldkey $name";
    my $signedreq = $self->_sign ($reqtext);

    my $url = "http://".$self->{name_warehouse_servers}."/put";
    my $req = HTTP::Request->new (POST => $url);
    $req->header ('Content-Length' => length $signedreq);
    $req->content ($signedreq);
    my $r = $self->{ua}->request ($req);

    if ($r->is_success)
    {
	if ($r->content =~ /^200 \Q$reqtext\E/)
	{
	    return 1;
	}
	else
	{
	    $self->{errstr} = "Server returned success but response was not in expected format: ".$r->content;
	}
    }
    else
    {
	$self->{errstr} = "http request failed: ".$r->status_line;
    }
    return undef;
}



=head2 fetch_manifest_key_by_name

 my $key = $whc->fetch_manifest_key_by_name ($name);

Looks up a named (signed) manifest.

Returns a key, which can be used to retrieve the manifest with
L</fetch_block>.  On failure, returns undef.

=cut


sub fetch_manifest_key_by_name
{
    my $self = shift;
    my $name = shift;

    my $url = "http://".$self->{name_warehouse_servers}."/get";
    my $req = HTTP::Request->new (POST => $url);
    $req->header ('Content-Length' => length $name);
    $req->content ($name);
    my $r = $self->{ua}->request ($req);

    if ($r->is_success)
    {
	my ($status, $key, $checkname) = split (" ", $r->content, 3);
	chomp $checkname;
	if ($status ne "200")
	{
	    $self->{errstr} = "server returned success but status $status != 200";
	    return undef;
	}
	if ($checkname ne $name)
	{
	    $self->{errstr} = "server sent wrong name ($checkname instead of $name)";
	    return undef;
	}
	return $key;
    }
    else
    {
	$self->{errstr} = "http request failed: ".$r->status_line;
	return undef;
    }
}



=head2 list_manifests

 my @manifest = $whc->list_manifests;
 foreach (@manifest)
 {
   my ($key, $name) = @$_;
   ...
 }

=cut

sub list_manifests
{
  my $self = shift;

  my $url = "http://".$self->{name_warehouse_servers}."/list";
  my $req = HTTP::Request->new (GET => $url);
  my $r = $self->{ua}->request ($req);

  my @ret;
  if ($r->is_success)
  {
    foreach (split ("\n", $r->content))
    {
      my ($key, $name, $keyid) = split (/\t/ ? "\t" : " ");
      last if (!defined $name);	# XXX should check md5 of entire response here
      push @ret, [$key, $name, $keyid];
    }
  }
  else
  {
    $self->{errstr} = $r->status_line;
    return undef;
  }

  return @ret;
}



=head2 job_list

    my $joblist = $whc->job_list;
    my $joblist = $whc->job_list (id_min => 123, id_max => 345);

=cut

sub job_list
{
    my $self = shift;
    $self->_read_cache;
    if (@_) { return $self->_job_list (@_); }
    $self->_refresh_job_list;
    return $self->{job_list_arrayref};
}

sub _job_list
{
    my $self = shift;
    my %what = @_;
    my $url = "http://".$self->{job_warehouse_servers}."/job/list";
    $url .= "?".$what{id_min}."-".$what{id_max}
	if $what{id_min} || $what{id_max};
    my $resp = $self->{ua}->get ($url);
    if ($resp->is_success)
    {
	my @ret;
	my $ctx = Digest::MD5->new;
	my $checkmd5;
	foreach (split /\n\n/, $resp->content)
	{
	    if (/^([0-9a-f]{32})\n$/)
	    {
		$checkmd5 = $1;
	    }
	    else
	    {
		$ctx->add ($_);
		$ctx->add ("\n\n");
		undef $checkmd5;
		my %h;
		foreach (split /\n/)
		{
		    my ($k, $v) = split /=/, $_, 2;
		    $h{$k} = $v;
		}
		$h{nnodes} = $self->_nodelist_to_nnodes ($h{nodes});
		$h{starttime_s} = $self->_to_unixtime ($h{starttime});
		$h{finishtime_s} = $self->_to_unixtime ($h{finishtime});
		push @ret, \%h;
	    }
	}
	if ($checkmd5 eq $ctx->hexdigest)
	{
	    return \@ret;
	}
	warn "Checksum mismatch";
	return undef;
    }
    return undef;
}

sub _nodelist_to_nnodes
{
    my $self = shift;
    my $nnodes = shift;
    if ($nnodes =~ /\D/)
    {
	my $nodelist = $nnodes;
	$nnodes = 0;
	while ($nodelist =~ /([^,\[]+)(?:\[(.*?)\])?/g)
	{
	    my $base = $1;
	    my $range = $2;
	    if (defined $range)
	    {
		for (split /,/, $range)
		{
		    if (/^(\d+)-(\d+)$/)
		    {
			for ($1..$2) { ++$nnodes; }
		    }
		    elsif (/^(\d+)/)
		    {
			++$nnodes;
		    }
		    else
		    {
			# can't parse node list!
			return 0;
		    }
		}
	    }
	    else
	    {
		++$nnodes;
	    }
	}
    }
    return $nnodes;
}

sub _to_unixtime
{
    my $self = shift;
    my $datestring = shift;
    return undef if !$datestring;
    return str2time ($datestring);
}



=head2 job_freeze

    $whc->job_freeze (id => 1234);

    $whc->job_freeze (id => 1234,
		      stop => 1);

=cut

sub job_freeze
{
    my $self = shift;
    my %job = @_;
    map { for ($job{$_}) { s/\\/\\\\/g; s/\n/\\n/g; } } keys %job;

    my $reqtext = join ("\n", map { $_."=".$job{$_} } keys %job);
    my $signedreq = $self->_sign ($reqtext);

    my $url = "http://".$self->{job_warehouse_servers}."/job/freeze";
    my $req = HTTP::Request->new (POST => $url);
    $req->header ('Content-Length' => length $signedreq);
    $req->content ($signedreq);
    my $r = $self->{ua}->request ($req);

    if ($r->is_success)
    {
	return 1;
    }
    else
    {
	$self->{errstr} = $r->content;
	return undef;
    }
}



=head2 job_new

    my $id = $whc->job_new (mrfunction => "zmd5",
			    revision => 836,
			    inputkey => "f171d0aa385d601d13d3f5292a4ed4c5",
			    knobs => "GZIP=yes\nFOO=bar",
			    nodes => 20,
			    stepspernode => 4,
			    photons => 1);

    my $id = $whc->job_new (thaw => 1234,
			    nodes => 10,
			    stepspernode => 3,
			    photons => 1);

=cut

sub job_new
{
    my $self = shift;
    my %job = @_;
    map { for ($job{$_}) { s/\\/\\\\/g; s/\n/\\n/g; } } keys %job;

    my $reqtext = join ("\n", map { $_."=".$job{$_} } keys %job);
    my $signedreq = $self->_sign ($reqtext);

    my $url = "http://".$self->{job_warehouse_servers}."/job/new";
    my $req = HTTP::Request->new (POST => $url);
    $req->header ('Content-Length' => length $signedreq);
    $req->content ($signedreq);
    my $r = $self->{ua}->request ($req);

    if ($r->is_success)
    {
	if ($r->content =~ /^\d+$/)
	{
	    return $&;
	}
	else
	{
	    $self->{errstr} = "Server reported success but did not supply a job id";
	}
    }
    else
    {
	$self->{errstr} = $r->content;
    }
    return undef;
}


sub _sign
{
    my $self = shift;
    my $text = shift;

    eval "use GnuPG::Interface";
    return $self->_fakesign ($text, "no GnuPG::Interface") if $@;

    my $gnupg = GnuPG::Interface->new();

    $gnupg->options->hash_init( armor    => 1,
                                homedir => $self->{gpg_homedir},
                              );

    my ( $input, $output, $error, $status ) =
       ( IO::Handle->new(),
         IO::Handle->new(),
         IO::Handle->new(),
         IO::Handle->new(),
       );

    my $handles = GnuPG::Handles->new( stdin  => $input,
                                       stdout => $output,
                                       stderr => $error,
                                       status => $status );

    my $pid = $gnupg->clearsign( handles => $handles );

    print $input $text;
    close $input;

    local $/ = undef;
    my $signed_text = <$output>;
    my $error_output = <$error>;
    my $status_output = <$status>;

    close $output;
    close $error;
    close $status;

    waitpid $pid, 0;

    if ($error_output ne '') {
      # Something went wrong during signing. 
      # fake signature for backwards compatibility
      return $self->_fakesign ($text, $error_output);
    }

    return $signed_text;

}

sub _fakesign
{
    my $self = shift;
    my $text = shift;
    my $error_output = shift;
    return "-----BEGIN PGP SIGNED MESSAGE-----\n"
	. "Faked\n\n"
    	. $text
	. "\n-----BEGIN PGP SIGNATURE-----\n"
	. "Error signing:\n$error_output\n\n" 
	. "Faked signature on " . `/bin/hostname` . " at " . `/bin/date +"%Y-%m-%d %H:%M:%S"` . "\n"
	. "-----END PGP SIGNATURE-----\n";
}


=head2 iostats

 print $whc->iostats;

Returns a human-readable summary of blocks and bytes sent to and
received from the warehouse, as well as average I/O bandwidth since
the client object was created.

=cut


sub iostats
{
    my $self = shift;
    my $elapsed = time - $self->{stats_time_created};
    if ($elapsed <= 0) { $elapsed = 1 };
    return sprintf
	("Mem In: %d bytes in %d/%d ops. Out: %d bytes in %d/%d ops.\n"
	 . "Mem In: %d Mbps. Out: %d Mbps. Total: %d Mbps.\n"
	 . "Disk In: %d bytes in %d/%d ops. Out: %d bytes in %d/%d ops.\n"
	 . "Disk In: %d Mbps. Out: %d Mbps. Total: %d Mbps.\n"
	 . "Keep In: %d bytes in %d/%d ops. Out: %d bytes in %d/%d ops.\n"
	 . "Keep In: %d Mbps. Out: %d Mbps. Total: %d Mbps.\n",
	 (map { $self->{$_} } qw(stats_memread_bytes
				 stats_memread_blocks
				 stats_memread_attempts
				 stats_memwrote_bytes
				 stats_memwrote_blocks
				 stats_memwrote_attempts)),
	 $self->{stats_memread_bytes} * 8 / $elapsed / 1000000,
	 $self->{stats_memwrote_bytes} * 8 / $elapsed / 1000000,
	 ($self->{stats_memread_bytes} +
	  $self->{stats_memwrote_bytes}) * 8 / $elapsed / 1000000,
	 (map { $self->{$_} } qw(stats_read_bytes
				 stats_read_blocks
				 stats_read_attempts
				 stats_wrote_bytes
				 stats_wrote_blocks
				 stats_wrote_attempts)),
	 $self->{stats_read_bytes} * 8 / $elapsed / 1000000,
	 $self->{stats_wrote_bytes} * 8 / $elapsed / 1000000,
	 ($self->{stats_read_bytes} +
	  $self->{stats_wrote_bytes}) * 8 / $elapsed / 1000000,
	 (map { $self->{$_} } qw(stats_keepread_bytes
				 stats_keepread_blocks
				 stats_keepread_attempts
				 stats_keepwrote_bytes
				 stats_keepwrote_blocks
				 stats_keepwrote_attempts)),
	 $self->{stats_keepread_bytes} * 8 / $elapsed / 1000000,
	 $self->{stats_keepwrote_bytes} * 8 / $elapsed / 1000000,
	 ($self->{stats_keepread_bytes} +
	  $self->{stats_keepwrote_bytes}) * 8 / $elapsed / 1000000);
}


sub _get_file_data
{
    my $self = shift;
    my $hash = shift;
    my $verifyflag = ref $_[0] ? undef : shift;
    my $options = shift || {};

    $verifyflag = $options->{verify} if !defined $verifyflag;

    die "can't get partial file data with verify=1"
	if $verifyflag && ($options->{offset} || exists $options->{length});

    $self->{errstr} = "No paths found for $hash";
    foreach my $trycache (1, 0)
    {
	my $pathref;
	if ($trycache)
	{
	    next if !$self->{memc};
	    $pathref = $self->{memc}->get
		($hash."\@".$self->{mogilefs_trackers})
		unless $self->{memcached_size_threshold} < 0;
	    next if !$pathref;
	}
	else
	{
	    my @paths = eval
	    {
		$self->{mogc}->get_paths ($hash, { noverify => 1 });
	    };
	    return undef if !@paths;
	    $pathref = \@paths;
	    $self->{memc}->set
		($hash."\@".$self->{mogilefs_trackers}, $pathref)
		unless $self->{memcached_size_threshold} < 0;
	}
	if ($self->{rand01} && @$pathref > 1)
	{
	    splice @$pathref, 0, 0, (splice @$pathref, 1);
	}
	foreach (@$pathref)
	{
	    my @headers;
	    if ($options->{offset} || $options->{length})
	    {
		my $from = $options->{offset} || 0;
		my $to = ($options->{length}
			  ? $options->{length} + $from - 1
			  : '*');
		push @headers, (Range => "bytes=$from-$to");
	    }
	    my $r = $self->{ua}->get ($_, @headers);
	    if ($r->is_success)
	    {
		print STDERR "Read $hash from $_\n"
		    if $self->{debug_mogilefs_paths};
		my $data = $r->content;
		if (!$verifyflag ||
		    $hash eq Digest::MD5::md5_hex ($data))
		{
		    return \$data;
		}
		else
		{
		    $self->{errstr} = "Checksum failed: $hash $_";
		    print STDERR $self->{errstr}."\n";
		}
	    }
	    else
	    {
		$self->{errstr} = $r->status_line;
	    }
	}
    }
    return undef;
}


=head2 block_might_exist

 foreach my $hash (@hashes)
 {
     $whc->block_might_exist ($hash) or print "block is missing: $hash";
 }

Returns 1 if it seems likely that the specified block exists in the
cache.

=cut


sub block_might_exist
{
    my $self = shift;
    my $hash = shift;
    my @paths = eval { $self->{mogc}->get_paths ($hash, { noverify => 1 }) };
    return @paths ? 1 : 0;
}



sub write_cache
{
    my $self = shift;
    $self->_read_cache;
    my $storeme = {};
    map { $storeme->{$_} = $self->{$_} } qw(job_list_arrayref
					    job_hashref
					    job_list_fetched
					    meta_stats_hashref
					    manifest_stats_hashref);
    my $cachefile = "/tmp/warehouse.cache.$<.".$self->{name_warehouse_servers};
    eval {
	use Storable "lock_store";
	lock_store $storeme, "$cachefile";
    };
}

sub _read_cache
{
    my $self = shift;
    return if $self->{already_read_cache};
    my $stored;
    eval {
	use Storable "lock_retrieve";
	$stored = lock_retrieve "/tmp/warehouse.cache.$<.".$self->{name_warehouse_servers};
    };
    if (ref $stored eq 'HASH')
    {
	map { $self->{$_} = $stored->{$_} } keys %$stored;
    }
    $self->{already_read_cache} = 1;
}

sub _refresh_job_list
{
    my $self = shift;
    $self->_read_cache;
    if (!ref $self->{job_list_arrayref} || $self->{job_list_fetched} < time - 60)
    {
	$self->{job_list_arrayref} = $self->_job_list;
	$self->{job_by_output} = {};
	foreach (@{$self->{job_list_arrayref}})
	{
	    if (!$self->{job_hashref}->{$_->{id}} ||
		$self->{job_hashref}->{$_->{id}}->{success} eq undef &&
		$self->{job_hashref}->{$_->{id}}->{cache_fetched} < time - 60)
	    {
		$self->{job_hashref}->{$_->{id}} = $_;
		$_->{cache_fetched} = time;
	    }
	    $self->{job_by_output}->{striphints($_->{outputkey})} = $_ if $_->{outputkey} && $_->{success};
	}
	$self->{job_list_fetched} = time;
    }
}


=head2 job_stats

 my $job = $whc->job_stats (1234);
 if ($job && $job->{meta_stats})
 {
     printf ("%d of %d slot seconds spent in successful jobsteps",
	     $job->{meta_stats}->{slot_seconds},
             $job->{meta_stats}->{success_seconds});
 }

=cut

sub job_stats
{
    my $self = shift;
    my $jobid = shift;

    $self->_read_cache;
    $self->_refresh_job_list;
    if (!ref $self->{job_hashref}->{$jobid})
    {
	return undef;
    }
    my $job = $self->{job_hashref}->{$jobid};
    if (!length $job->{success} && $job->{cache_fetched} < time - 30)
    {
	my $newjoblist = $self->job_list (id_min => $jobid, id_max => $jobid);
	if (@$newjoblist == 1)
	{
	    $job = $newjoblist->[0];
	    $self->{job_hashref}->{$jobid} = $job;
	}
    }
    if ($job->{finishtime_s} && $job->{starttime_s})
    {
	$job->{elapsed} = $job->{finishtime_s} - $job->{starttime_s};
	$job->{nodeseconds} = $job->{elapsed} * $job->{nnodes};
    }
    if ($job->{metakey} && !$self->{meta_stats_hashref}->{$job->{metakey}})
    {
	my $stats = { frozentokeys => {} };
	$self->{meta_stats_hashref}->{$job->{metakey}} = $stats;

	my $logstarttime;
	my $failure_seconds = 0;
	my $success_seconds = 0;
	my $slots = 0;
	my $s = new Warehouse::Stream (whc => $self,
				       hash => [split (",", $job->{metakey})]);
	$s->rewind();
	while (my $dataref = $s->read_until (undef, "\n"))
	{
	    if (!defined $logstarttime && $$dataref =~ /^(\S+) /)
	    {
		$logstarttime = $1;
		$logstarttime =~ s/_/ /;
		$logstarttime = str2time ($logstarttime);
	    }
	    if ($$dataref =~ /^\S+ \d+ \d+ \d+ (success|failure) in (\d+) seconds\n/)
	    {
		$failure_seconds += $2 if $1 eq "failure";
		$success_seconds += $2 if $1 eq "success";
	    }
	    elsif ($$dataref =~ /^(\S+) \d+ \d+  node \S+ - (\d+) slots\n/)
	    {
		$slots += $2;
	    }
	    elsif ($$dataref =~ /^(\S+) \d+ \d+  frozento ?key is (\S+)/)
	    {
		my $logtime = $1;
		my $frozentokey = $2;
		$logtime =~ s/_/ /;
		$logtime = str2time ($logtime);
		my $slot_seconds = $slots * ($logtime - $logstarttime);
		$stats->{frozentokeys}->{$frozentokey} = {
		    starttime => $logstarttime,
		    frozentime => $logtime,
		    elapsed => $logtime - $logstarttime,
		    slots => $slots,
		    slot_seconds => $slot_seconds,
		    success_seconds => $success_seconds,
		    failure_seconds => $failure_seconds,
		    idle_seconds => $slot_seconds - $failure_seconds - $success_seconds,
		};
	    }
	}
	my $slot_seconds = $slots * $job->{elapsed};

	$stats->{slots} = $slots;
	$stats->{slot_seconds} = $slot_seconds;
	$stats->{failure_seconds} = $failure_seconds;
	$stats->{success_seconds} = $success_seconds;
	$stats->{idle_seconds} = $slot_seconds - $failure_seconds - $success_seconds;
	foreach (qw(failure success idle))
	{
	    if ($stats->{slot_seconds} > 0)
	    {
		$stats->{$_."_percent"} =
		    sprintf ("%.2f",
			     100 * $stats->{$_."_seconds"} / $stats->{slot_seconds});
	    }
	}
    }
    $job->{meta_stats} = $self->{meta_stats_hashref}->{$job->{metakey}} || {};
    return $job;
}

sub job_follow_input
{
    my $self = shift;
    my $targetjob = shift;

    $self->_read_cache;
    $self->_refresh_job_list;
    my $previous = $self->{job_by_output}->{striphints($targetjob->{inputkey})};
    return $previous
	if ($previous
	    && (!$targetjob->{id} || $previous->{id} < $targetjob->{id}));
    
    foreach (@{$self->{job_list_arrayref}})
    {
	last if $_->{id} >= $targetjob->{id};
	return $_ if $_->{outputkey} eq $targetjob->{inputkey};
    }
    return undef;
}

sub striphints
{
    for (@_)
    {
	s/\+([^,]*)//g;
    }
    return wantarray ? @_ : join (",", @_);
}

sub job_follow_thawedfrom
{
    my $self = shift;
    my $targetjob = shift;

    $self->_read_cache;
    my $thawhash = $targetjob->{thawedfromkey};
    return undef if !$thawhash;

    my ($firstblock) = $thawhash =~ /^([0-9a-f]{32})/;
    my $thawed = $self->fetch_block ($firstblock,
				     { verify => 0, length => 500 })
	or die "fetch_block($firstblock) failed";
    $thawed =~ /^job (\d+)\n/
	or die "could not parse thawedfromkey $thawhash";
    ($1 < $targetjob->{id})
	or die "thawedfromkey $thawhash claims to be from job $1, which was not even submitted yet when job ".$targetjob->{id}." was submitted.\n";
    ($targetjob = $self->job_stats ($1))
	or die "couldn't find job $1 in job list";

    if (!$targetjob->{meta_stats}->{frozentokeys}->{$thawhash})
    {
	warn "WARNING: thawedfromkey $thawhash does not appear in meta stream of job "
	    .$targetjob->{id}." -- continuing anyway.\n";
    }
    return $targetjob;
}

=head2 manifest_data_size

    my $bytes = $whc->manifest_data_size ($key);

=cut

sub manifest_data_size
{
    my $self = shift;
    my $key = shift;

    $self->_read_cache;
    if ($self->{manifest_stats_hashref}->{$key} &&
	$self->{manifest_stats_hashref}->{$key}->{data_size})
    {
	return $self->{manifest_stats_hashref}->{$key}->{data_size};
    }

    my $s = new Warehouse::Stream (whc => $self,
				   hash => [split (",", $key)]);
    $s->rewind;
    my $data_size = 0;
    while (my $dataref = $s->read_until (undef, "\n"))
    {
	while ($$dataref =~ / [a-f0-9]{32}.*?(\+(\d+))?/g)
	{
	    if (!defined $1)
	    {
		my $blockdata = $self->{whc}->fetch_block_ref ($_);
		$data_size += length $$blockdata;
	    }
	    else
	    {
		$data_size += $2;
	    }
	}
    }
    $self->{manifest_stats_hashref}->{$key} = { data_size => $data_size };
    return $data_size;
}


sub errstr
{
    my $self = shift;
    return $self->{errstr};
}


sub _cryptsetup
{
    my $self = shift;
    $self->{config}->{encrypt} ||= [];
    if ($ENV{ENCRYPT_ALL} && !@{$self->{config}->{encrypt}})
    {
	$self->{config}->{encrypt} = [ split (/\s*,\s*/, $ENV{ENCRYPT_ALL}) ];
    }
    $self->{config}->{cryptmap_name_prefix} ||= "/gpg/".Digest::MD5::md5_hex (join (",", sort @{$self->{config}->{encrypt}}))."/";

    if (-w "$ENV{HOME}/.gnupg" || (-w $ENV{HOME} && !-e "$ENV{HOME}/.gnupg"))
    {
	$self->{gpg_homedir} = "$ENV{HOME}/.gnupg";
    }
    elsif (-w ($self->{gpg_homedir} = "/etc/warehouse/.gnupg"))
    {
	;
    }
    else
    {
	$self->{config}->{nodecrypt} = 1;
	return;
    }

    eval "use GnuPG::Interface";
    return if $@;

    eval {
	my $gnupg = GnuPG::Interface->new();
	$gnupg->options->hash_init (homedir => $self->{gpg_homedir});

	my ( $input, $output, $error, $status ) =
		( IO::Handle->new(),
		  IO::Handle->new(),
		  IO::Handle->new(),
		  IO::Handle->new(),
		);

	my $handles = GnuPG::Handles->new( stdin  => $input,
					   stdout => $output,
					   stderr => $error,
					   status => $status );

	open(TMP,"/etc/warehouse/gnupg-keys.pub.asc");
	my $pid = $gnupg->import_keys ( handles => $handles);

	local $/ = undef;
	print $input <TMP>;
	close $input;
	close TMP;

	my $imported = <$output>;
	my $error_output = <$error>;
	my $status_output = <$status>;

	close $output;
	close $error;
	close $status;

	waitpid $pid, 0;
    };
}


sub _cryptmap_write
{
    my $self = shift;
    my $plainhash = shift;
    my $enchash = shift;
    return undef if !@{$self->{config}->{encrypt}};
    my $cryptmap_name = $self->{config}->{cryptmap_name_prefix}.$plainhash;
    my $oldenchash = $self->fetch_manifest_key_by_name ($cryptmap_name);

    printf STDERR ("gpg: _cryptmap_write %s %s -> %s\n",
		   $cryptmap_name,
		   $oldenchash,
		   $enchash,
		   )
	if $ENV{DEBUG_GPG};

    local $self->{name_warehouse_servers} = $self->{cryptmap_name_controllers};
    return $self->store_manifest_by_name
	($enchash,
	 $oldenchash,
	 $cryptmap_name);
}


sub _cryptmap_fetchable
{
    # Return the hash (md5+size) of a block which can be decrypted to
    # yield $$dataref -- ie. look md5($$dataref) in the cryptmap db
    # and make sure the encrypted block can really be decrypted.

    my $self = shift;
    my $dataref = shift;
    my $hash = shift;		# optional

    return undef if !@{$self->{config}->{encrypt}};

    $hash ||= Digest::MD5::md5_hex ($$dataref) . "+" . length($$dataref);

    my $enchash;
    my $encdataref;
    eval
    {
	local $self->{name_warehouse_servers} =
	    $self->{cryptmap_name_controllers};
	$enchash = $self->fetch_manifest_key_by_name
	    ($self->{config}->{cryptmap_name_prefix}.$hash)
	    or die "no cryptmap for $hash";

	$enchash =~ s/\+G[^\+]*//g;
	$enchash .= "+GS".length($$dataref);
	my ($plainmd5) = $hash =~ /^([0-9a-f]+)/;
	$enchash .= "+GM$plainmd5";

	$encdataref = $self->fetch_block_ref
	    ($enchash, { verify => 1, nowarn => 1, nodecrypt => 1 })
	    or die "fetch $enchash fail";
	$$encdataref ne $$dataref or die "encrypted eq orig";
	my $decdataref = $self->_decrypt_block ($encdataref)
	    or die "decrypt $enchash fail";
	$$decdataref eq $$dataref or die "decrypted ne orig";
    };
    $enchash = undef if $@;

    printf STDERR "gpg: _cryptmap_fetchable %s %s (%s)\n", $hash, $enchash, $@
	if $ENV{DEBUG_GPG};

    return ($enchash, $encdataref) if wantarray;
    return $enchash;
}


sub _encrypt_block
{
    # Encrypt data using key specified by $self->{config}->{encrypt}.
    # Return scalarref with encrypted data.  If encryption fails, die.

    my ($self, $dataref) = @_;

    printf STDERR "gpg: encrypt %s\n", Digest::MD5::md5_hex($$dataref)
	if $ENV{DEBUG_GPG};

    eval "use GnuPG::Interface";
    die "_encrypt_block() GnuPG::Interface not found" if $@;
    die "_encrypt_block() public key id(s) not set for encryption"
	if !@{$self->{config}->{encrypt}};

    my $gnupg = GnuPG::Interface->new();

    $gnupg->options->hash_init( armor    => 0,
                                homedir => $self->{gpg_homedir},
                              );

    my $child = open PLAIN, "-|";
    die "Pipe failed: $!" if !defined $child;
    if ($child == 0)
    {
	close STDIN;
	print $$dataref;
	close STDOUT;
	exit 0;
    }

    my ( $input, $output, $error, $status ) =
       ( IO::Handle->new(),
         IO::Handle->new(),
         IO::Handle->new(),
         IO::Handle->new(),
       );
    $input->fdopen (fileno(PLAIN),"r") or die;

    my $handles = GnuPG::Handles->new( stdin  => $input,
                                       stdout => $output,
                                       stderr => $error,
                                       status => $status );
    $handles->options ('stdin', { direct => 1 } );

    foreach my $key (@{$self->{config}->{encrypt}}) {
      $gnupg->options->push_recipients( $key );
    }

    my $pid = $gnupg->encrypt( handles => $handles );

    local $/ = undef;
    my $encrypted = <$output>;
    my $error_output = <$error>;
    my $status_output = <$status>;

    close $output;
    close $error;
    close $status;
    close $input;

    waitpid $pid, 0;

    if ($error_output ne '') {
      die "_encrypt_block() error encrypting:\nError output: $error_output\nStatus output: $status_output\n";
    }

    printf STDERR "gpg: encrypt -> %s\n", Digest::MD5::md5_hex($encrypted)
	if $ENV{DEBUG_GPG};
    return \$encrypted;

}

sub _decrypt_block
{
    # Decrypt data using appropriate key (using the keys specified by
    # $self->{config}->{encrypt} -- or try using other keys if that
    # doesn't work).  Return scalarref with decrypted data.  Die if
    # decryption isn't possible.

    my ($self, $dataref) = @_;

    return $dataref if $self->{config}->{nodecrypt};

    printf STDERR "gpg: decrypt %s\n", Digest::MD5::md5_hex($$dataref)
	if $ENV{DEBUG_GPG};

    my $child = open D, "-|";
    die "couldn't fork" if !defined $child;
    if ($child == 0)
    {
	close STDIN;
	$self->_unsafe_decrypt_block ($dataref);
	exit 0;
    }
    local $/ = undef;
    my $decrypted = <D>;
    close D;
    return $dataref if $decrypted eq "";
    return \$decrypted;
}

sub _unsafe_decrypt_block
{
    my ($self, $dataref) = @_;

    eval "use GnuPG::Interface";
    die "_decrypt_block() GnuPG::Interface not found" if $@;

    my $gnupg = GnuPG::Interface->new();
    $gnupg->options->hash_init( armor    => 1,
                                homedir => $self->{gpg_homedir},
                              );

    my ( $input, $output, $error, $status, $passphrase ) =
       ( IO::Handle->new(),
         IO::Handle->new(),
         IO::Handle->new(),
         IO::Handle->new(),
	 IO::Handle->new(),
       );
    $output->fdopen(fileno(STDOUT),"w");

    my $handles = GnuPG::Handles->new( stdin      => $input,
                                       stdout     => $output,
                                       stderr     => $error,
                                       status     => $status,
				       passphrase => $passphrase);
    $handles->options ('stdout', { "direct" => 1 } );

    my $pid = $gnupg->decrypt( handles => $handles );

    close $passphrase;

    print $input $$dataref;
    close $input;

    local $/ = undef;
    my $error_output = <$error>;
    my $status_output = <$status>;

    close $output;
    close $error;
    close $status;

    waitpid $pid, 0;

    if ($status_output =~ /NODATA/) {
	# This data is not encrypted. Return input unchanged.
	print $$dataref;
	return 1;
    }

    if ($status_output =~ /NO_SECKEY/) {
	# Properly encrypted data, but we don't have the secret key. Return input unchanged.
	print $$dataref;
	return 1;
    }

    if ($status_output !~ /DECRYPTION_OKAY/) {
      # Something else went wrong...
      die "_decrypt_block() error decrypting:\nError output: $error_output\nStatus output: $status_output\n";
    }

    return 1;
}

sub _verify
{
  warn "gpg: _verify\n" if $ENV{DEBUG_GPG};

  my $text = shift;

  eval "use GnuPG::Interface";
  return (0,'') if $@;

  my $gnupg = GnuPG::Interface->new();

  $gnupg->options->hash_init( armor    => 1,
                              homedir => $self->{gpg_homedir},
                            );
  my ( $input, $output, $error, $status ) =
     ( IO::Handle->new(),
       IO::Handle->new(),
       IO::Handle->new(),
       IO::Handle->new(),
     );

  my $handles = GnuPG::Handles->new( stdin  => $input,
                                     stdout => $output,
                                     stderr => $error,
                                     status => $status );

  my $pid = $gnupg->verify( handles => $handles );

  print $input $text;
  close $input;

  local $/ = undef;
  my $returned_text = <$output>;
  my $error_output = <$error>;
  my $status_output = <$status>;

  close $output;
  close $error;
  close $status;

  waitpid $pid, 0;

  if (($status_output =~ /VALIDSIG/) && ($status_output =~ /GOODSIG/)) {
    warn "gpg: good signature, keyid=$keyid\n" if $ENV{DEBUG_GPG};
    my ($keyid) = $status_output =~ /GOODSIG .{8}(.{8}) /;
    return (1,$keyid);
  } else {
    my $safetext = $text;
    $safetext =~ s/^(.{1024}).*/$1/s;
    $safetext =~ s/[^-\w\(\)\@]/_/gs;
    warn "gpg: failed: $safetext\n";
    warn "gpg: error: $error_output\n";
    warn "gpg: status: $status_output\n";
    return (0,'');
  }
}

1;

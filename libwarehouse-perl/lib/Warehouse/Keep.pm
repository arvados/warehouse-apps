# -*- mode: perl; perl-indent-level: 4; -*-

package Warehouse::Keep;

use Warehouse;
use HTTP::Daemon;
use POSIX; 
use HTTP::Response;
use Digest::MD5 qw(md5_hex);
use Warehouse;
use Fcntl ':flock';
use JSON;
use Data::UUID;
use YAML;

use strict;

=head1 NAME

Warehouse::Keep -- Long term storage daemon.  Two supported actions:
(1) PUT /md5 --> store data with specified md5
(2) GET /md5 --> retrieve data
(3) DELETE /md5 --> delete data (yet unimplemented; only controller can do it)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

 use Warehouse::Keep;

 my $daemon = Warehouse::Keep->new;
 $daemon->run;

=head1 METHODS

=head2 new

 my $daemon = Warehouse::Keep->new( %OPTIONS );

Creates a new server.  Returns the new object on success.  Dies on
failure.

=head3 Options

=over

=item Directories

Reference to an array of directories where files may be stored.  For
example:

  [ "/sda3/keep",
    "/sdb3/keep",
    "/sdc1/keep" ]

=item ListenAddress

IP address to listen on.  Default is "0.0.0.0".

=item ListenPort

Port number to listen on.  Default is 25107.

=back

=cut

my $children = 0;
my %Children = ();
my $TotalChildren = 0;
my $TERM = 0;


sub new
{
    my $class = shift;
    my $self = { @_ };
    bless ($self, $class);
    return $self->_init();
}

sub _init
{
    my Warehouse::Keep $self = shift;
    
    ref $self->{Directories} eq "ARRAY" or die "No Directories specified";
    $#{$self->{Directories}} >= 0 or die "No Directories specified";

    $self->{ListenAddress} = "0.0.0.0"
	if !defined $self->{ListenAddress};

    $self->{ListenPort} = "25107"
	if !defined $self->{ListenPort};

    $self->{Reuse} = 1
	if !defined $self->{Reuse};

    $self->{daemon} = new HTTP::Daemon
	( LocalAddr => $self->{ListenAddress},
	  LocalPort => $self->{ListenPort},
	  Reuse => $self->{Reuse} );

    $self->{daemon} or die "HTTP::Daemon::new failed: $!";

    $self->{whc} = new Warehouse;

    $self->{node_status} = {
	'time' => scalar time,
	'df' => scalar `df --block-size=1k`,
	'dirs' => {},
    };
    foreach (@{$self->{Directories}}) {
	$self->{node_status}->{dirs}->{$_} = {
	    'status' => '',
	};
    }

    $SIG{HUP} = $SIG{INT} = $SIG{TERM} = sub {
      # Any sort of death trigger results in death of all
      my $sig = shift;
      $SIG{$sig} = 'DEFAULT';
      $Warehouse::Keep::TERM = 1;
      kill 'INT' => keys %Warehouse::Keep::Children;
      warn "$$ killed by $sig\n";
    };

    $self->{ChildLifeTime} = 1;

    $Warehouse::Keep::TotalChildren = $ENV{KEEP_MAX_SERVERS} || 32;
    print STDERR "Total children: " . $Warehouse::Keep::TotalChildren . "\n" if ($ENV{DEBUG});

    $Warehouse::Keep::children = 0;

    return $self;
}

sub NewChild
{
    my $self = shift;
    # Daemonize away from the parent process.
    my $pid;
    die "Cannot fork child: $!\n" unless defined ($pid = fork);
    if ($pid) {
        $Warehouse::Keep::Children{$pid} = 1;
        $Warehouse::Keep::children++;
        print STDERR "forked new child, we now have " . $Warehouse::Keep::children . " children\n" if ($ENV{DEBUG});
        return;
    }
    print STDERR "CHILD: child happy - childlifetime is $self->{ChildLifeTime}\n" if ($ENV{DEBUG});

    $SIG{INT} = $SIG{HUP} = $SIG{TERM} = $SIG{CHLD} = 'DEFAULT';

    # Loop for a certain number of times
    my $i = 0;

    while ($i < $self->{ChildLifeTime}) {
        print STDERR "CHILD: in loop\n" if ($ENV{DEBUG});
        $i++;
        # Accept a connection from HTTP::Daemon
        my $c = $self->{daemon}->accept or last;
        print STDERR "CHILD: accepted a connection\n" if ($ENV{DEBUG});
        $c->autoflush(1);
        print STDERR "CHILD: connect:". $c->peerhost . "\n" if ($ENV{DEBUG});

        $self->process($c);
    }

    warn "child terminated after $i requests" if $i > 1;
    exit;
}


=head2 url

  my $url = $daemon->url;

Returns the base url of the server (eg. http://1.2.3.4:25107/).

=cut


sub url
{
    my $self = shift;
    return $self->{daemon}->url;
}


=head2 run

  $daemon->run;

Listens for connections, and handles requests from clients.

=cut


sub run {
  my $self = shift;

  print STDERR "children at: $Warehouse::Keep::children\n" if ($ENV{DEBUG});
  print STDERR "TotalChildren at: $Warehouse::Keep::TotalChildren\n" if ($ENV{DEBUG});

  # If this warehouse was configured with an API host, then ping it
  # so it knows about our keeps.
  $self->{api_host} = $ENV{API_PORT_443_TCP_ADDR};
  $self->{api_port} = $ENV{API_PORT_443_TCP_PORT};
  $self->{api_auth_token} = $Warehouse::warehouses->[0]->{api_auth_token};
  if ($self->{api_host}) {
      $self->_ping_api_host();
  }

  while (!$Warehouse::Keep::TERM) {
    for (my $i = $Warehouse::Keep::children; $i < $Warehouse::Keep::TotalChildren; $i++ ) {
      $self->NewChild();
      print STDERR "Forked new; children is at $Warehouse::Keep::children; TotalChildren is at $Warehouse::Keep::TotalChildren\n" if ($ENV{DEBUG});
    }
    my $stiff = wait;
    if ($stiff > 0) {
        printf STDERR "child $stiff terminated, status %x", $? if $ENV{DEBUG};
        delete $Warehouse::Keep::Children{$stiff};
        $Warehouse::Keep::children--;
        print STDERR " children=$Warehouse::Keep::children\n" if $ENV{DEBUG};
    }
  }

}

sub process 
{
    my $self = shift;
    my $c = shift;
    my $whc = new Warehouse;
    while (my $r = $c->get_request)
    {
        print(scalar (localtime) .
    	  " " . $c->peerhost() .
    	  " R" .
    	  " " . $r->method .
    	  " " . (map { s/[^\/\w_]/_/g; $_; } ($r->url->path_query))[0] .
    	  "\n");

    	if ($r->method eq "GET" || $r->method eq "HEAD")
    	{
    	    if ($r->url->path =~ /^\/index(\/([0-9a-f]{0,32}))?$/)
    	    {
                if (!defined $Warehouse::keep_controller_ip ||
                    $c->peerhost() ne $Warehouse::keep_controller_ip)
                {
                    my $resp = HTTP::Response->new
                        (401, "Unauthorized",
                         [], "Only the controller can do that.\n");
                    $c->send_response ($resp);
                    last;
                }
    		_index_callback_init ($self, $2);
    		$c->send_response (HTTP::Response->new
				   (200, "OK", [],
				    \&_index_callback));
    		last;
    	    }
	    if ($r->url->path =~ /^\/is_full$/)
	    {
		$c->send_response (HTTP::Response->new
				   (200, "OK", [],
				    $self->_is_full() ? "1" : "0"));
		last;
	    }
	    if ($r->url->path =~ /^\/status\.json$/)
	    {
		if (scalar time - $self->{node_status}->{'time'} > 300) {
		    $self->{node_status}->{'df'} = `df --block-size=1k`;
		    $self->{node_status}->{'time'} = scalar time;
		}
		$self->get_last_errors();

		map { $self->_is_full($_) } @{$self->{Directories}};

		my @disk_devices = `ls /dev/| egrep '^(s|xv|h)d'`;
		chomp @disk_devices;
		$self->{node_status}->{'disk_devices'} = \@disk_devices;

		$c->send_response
		    (HTTP::Response->new
		     (200, "OK", [],
		      JSON::to_json
		      ( $self->{node_status} )));
		last;
	    }
    	    my ($md5) = $r->url->path =~ /^\/([0-9a-f]{32})$/;
    	    if (!$md5)
    	    {
    		$c->send_response (HTTP::Response->new
				   (400, "Bad request",
				    [], "Bad request\n"));
    		last;
    	    }
    	    my ($dataref, $blocksize) = $self->_fetch
		($md5, $r->method eq "HEAD" ? { "head" => 0 } : {});
    	    if (!ref $dataref)
    	    {
    		$c->send_response (HTTP::Response->new
    			       (404, "Not found", [], "Not found\n"));
    		last;
    	    }
    	    $c->send_response (HTTP::Response->new
			       (200, "OK",
				["X-Block-Size", $blocksize],
				$$dataref));
    	}
    	elsif ($r->method eq "PUT")
    	{
	    my ($md5) = $r->url->path =~ /^\/([0-9a-f]{32})$/;
	    if (!$md5)
	    {
		$c->send_response (HTTP::Response->new
				   (400, "Bad request",
				    [], "Bad request\n"));
		last;
	    }

	    # verify signature
	    $r->content =~ /(-----BEGIN PGP SIGNED MESSAGE-----\n.*?\n\n(.*?)\n-----BEGIN PGP SIGNATURE.*?-----END PGP SIGNATURE-----\n)(.*)$/s;
	    my $signedmessage = $1;
	    my $plainmessage = $2;
	    my $newdata = $3;

#	    my ($verified,$keyid) = $whc->_verify($signedmessage);
#
#	    if (!$verified)
#	    {
#		$self->_log ($c, "SigFail");
#	    }
	    my ($checktime, $checkmd5) = split (/ /, $plainmessage, 2);
	    $checktime += 0;
#	    if (0 && !$verified)
#	    {
#		my $resp = HTTP::Response->new
#		    (401, "SigFail",
#		     [], "Signature verification failed.\n");
#		$c->send_response ($resp);
#		last;
#	    }
	    if (time - $checktime > 300 ||
		time - $checktime < -300)
	    {
		my $resp = HTTP::Response->new
		    (401, "TimeFail",
		     [], "Timestamp verification failed.\n");
		$c->send_response ($resp);
		last;
	    }
	    if ($checkmd5 ne $md5)
	    {
		my $resp = HTTP::Response->new
		    (401, "MD5Fail",
		     [], "MD5 verification failed.\n");
		$c->send_response ($resp);
		last;
	    }
#	    if (!$verified)
#	    {
#		$self->_log ($c, "SigFail ignored");
#	    }

	    my ($dataref, $blocksize) = $self->_fetch ($md5, { touch => 1 });
	    if ($dataref && ($newdata eq "" || $$dataref eq $newdata))
	    {
		$c->send_response (HTTP::Response->new
				   (200, "OK",
				    ["X-Block-Size", $blocksize],
				    "$md5\n"));
		last;
	    }

	    if ($dataref)
	    {
		$c->send_response (HTTP::Response->new
				   (400, "Collision",
				    [], "$md5\n"));
		last;
	    }

	    my $metadata = "remote_addr=".$c->peerhost()."\n"
		. "time=".$checktime."\n"
		. "\n"
		. "$signedmessage";

	    if ($newdata eq "")
	    {
		if (!$self->{whc})
		{
		    $c->send_response (HTTP::Response->new
				       (500, "No client object",
					[], "No client object\n"));
		    last;
		}
		if (!defined ($newdata = $self->{whc}->fetch_block ($md5)))
		{
		    $c->send_response (HTTP::Response->new
				       (404, "Data not found in cache",
					[], "Data not found in cache\n"));
		    last;
		}
	    }

	    if ($self->_is_full())
	    {
		$c->send_response (HTTP::Response->new
				   (503, "Full", [], "Full"));
		last;
	    }

	    if (!$self->_store ($md5, \$newdata, \$metadata))
	    {
		$self->_log($c,$self->{errstr});
		my $status_number = 500;
		my $status_phrase = "Fail";
		if ($self->{errstr} =~ /^([^,]*no space left on device,* *)+$/i)
		{
		    $status_number = 503;
		    $status_phrase = "Full";
		}
		$c->send_response (HTTP::Response->new
				   ($status_number, $status_phrase,
				    [], $self->{errstr}));
		last;
	    }
	    $c->send_response (HTTP::Response->new
			       (200, "OK",
				["X-Block-Size", length($newdata)],
				"$md5\n"));
        }
        elsif ($r->method eq "DELETE")
        {
	    my ($md5) = $r->url->path =~ /^\/([0-9a-f]{32})$/;
	    if (!$md5)
	    {
		$c->send_response (HTTP::Response->new
				   (400, "Bad request",
				    [], "Bad request\n"));
		last;
	    }

	    # verify signature
	    $r->content =~ /(-----BEGIN PGP SIGNED MESSAGE-----\n.*?\n\n(.*?)\n-----BEGIN PGP SIGNATURE.*?-----END PGP SIGNATURE-----\n)(.*)$/s;
	    my $signedmessage = $1;
	    my $plainmessage = $2;
	    my $newdata = $3;

	    my ($verified,$keyid) = $whc->_verify($signedmessage);

	    if (!$verified)
	    {
		$self->_log($c, "SigFail");
	    }
	    my ($checktime, $checkmd5) = split (/ /, $plainmessage, 2);
	    $checktime += 0;
	    if (0 && !$verified)
	    {
		my $resp = HTTP::Response->new
		    (401, "SigFail",
		     [], "Signature verification failed.\n");
		$c->send_response ($resp);
		last;
	    }
	    if (time - $checktime > 300 ||
		time - $checktime < -300)
	    {
		my $resp = HTTP::Response->new
		    (401, "TimeFail",
		     [], "Timestamp verification failed.\n");
		$c->send_response ($resp);
		last;
	    }
	    if ($checkmd5 ne $md5)
	    {
		my $resp = HTTP::Response->new
		    (401, "MD5Fail",
		     [], "MD5 verification failed.\n");
		$c->send_response ($resp);
		last;
	    }
	    if (!$verified)
	    {
		$self->_log($c, "SigFail ignored");
	    }
	    if (!defined $Warehouse::keep_controller_ip ||
		$c->peerhost() ne $Warehouse::keep_controller_ip)
	    {
		my $resp = HTTP::Response->new
		    (401, "Unauthorized",
		     [], "Only the controller can do that.\n");
		$c->send_response ($resp);
		last;
	    }

	    if ($self->_delete ($md5))
	    {
		$c->send_response (HTTP::Response->new
				   (200, "OK", [], "$md5\n"));
	    }
	    else
	    {
		$self->_log($c,$self->{errstr});
		$c->send_response (HTTP::Response->new
				   (500, "Fail", [], $self->{errstr}));
		last;
	    }
        }
        else
        {
	    $c->send_response (HTTP::Response->new
			       (501, "Not implemented",
				[], "Not implemented.\n"));
	    last;
        }
    }
    $c->close if $c;
}


my $_callback_self;
my $_callback_search;
my $_callback_dir;
my @_callback_dirs;
sub _index_callback_init
{
    $_callback_self = shift;
    $_callback_search = shift;
    @_callback_dirs = @ { $_callback_self->{Directories} };

    # open the first dir in the list [that works] in preparation for callback
    while (@_callback_dirs &&
	   !(opendir (D, ($_callback_dir = shift @_callback_dirs))))
    { }
}

sub _index_callback
{
    my $file;

    # get the next available file, opening the next directory if necessary
    while (1)
    {
	$file = readdir D;

	if (!defined $file)
	{
	    # no files remaining in D, so open the next dir in the list
	    while (1)
	    {
		closedir D;

		# finished searching all dirs?
		return undef if !@_callback_dirs;

		$_callback_dir = shift @_callback_dirs;
		last if opendir D, $_callback_dir;
	    }
	    next;
	}

	if (defined $_callback_search)
	{
	    if (length $_callback_search > length $file)
	    {
		next if $file ne
		    substr ($_callback_search, 0, length $file);
	    }
	    else
	    {
		next if $_callback_search ne
		    substr ($file, 0, length $_callback_search);
	    }
	}

	# descend into subdirs using _scandir()
	if ($file =~ /^[0-9a-f]{1,31}$/ &&
	    -d "$_callback_dir/$file") {
	    my $index = "";
	    $_callback_self->_scandir ("$_callback_dir/$file", \$index);
	    next if !length $index;
	    return $index;
	}

	# skip *.meta and other files that aren't data blocks
	next if $file !~ /^[0-9a-f]{32}$/;

	# found a data file; end loop
	last;
    }

    # the following block only handles the case where data files were
    # stored with old code (all in one /keep dir instead of in
    # /keep/{prefix} subdirs)

    my $index = $file;
    my @stat = stat "$_callback_dir/$file";
    if (@stat)
    {
	$index .= "+$stat[7]";
	my $mtime = $stat[9];
	@stat = stat "$_callback_dir/$file.meta";
	if (@stat && $mtime < $stat[9])
	{
	    $mtime = $stat[9];
	}
	$index .= " $mtime";
    }
    $index .= "\n";
    return $index;
}


sub _index
{
    my $self = shift;
    my $dirs = $self->{Directories};
    my $index = "";
    for my $dir (@$dirs)
    {
	$self->_scandir ($dir, \$index);
    }
    return $index;
}


sub _scandir
{
    my $self = shift;
    my $dir = shift;
    my $index = shift;
    my $dirhandle;
    opendir ($dirhandle, "$dir/") or return;
    while (local $_ = readdir $dirhandle)
    {
	if (/^[0-9a-f]{3}$/) {
	    $self->_scandir ("$dir/$_", $index);
	}
	elsif (/^[0-9a-f]{32}$/)
	{
	    if (defined $_callback_search &&
		substr($_, 0, length $_callback_search) ne $_callback_search)
	    {
		next;
	    }
	    $$index .= $_;
	    my @stat = stat "$dir/$_";
	    if (@stat)
	    {
		$$index .= "+$stat[7]";
		my $mtime = $stat[9];
		@stat = stat "$dir/$_.meta";
		if (@stat && $mtime < $stat[9])
		{
		    $mtime = $stat[9];
		}
		$$index .= " $mtime";
	    }
	    $$index .= "\n";
	}
    }
    closedir $dirhandle;
}


sub _delete
{
    my $self = shift;
    my $md5 = shift;
    my $dirs = $self->{Directories};
    my $fail = 0;
    for my $dir (@$dirs)
    {
	if (unlink "$dir/$md5")
	{
	    unlink "$dir/$md5.meta";
	}
	elsif (-e "$dir/$md5")
	{
	    $fail = 1;
	    $self->{errstr} = $!;
	}
    }
    return $fail ? undef : 1;
}


sub _fetch
{
    my $self = shift;
    my $md5 = shift;
    my $opt = shift;
    my $dirs = $self->{Directories};
    for my $dir (@$dirs)
    {
	my $realdir;
	my ($first12bits) = $md5 =~ /^(...)/;
	if (sysopen (F, "$dir/$md5", O_RDONLY))
	{
	    $realdir = $dir;
	}
	elsif (sysopen (F, "$dir/$first12bits/$md5", O_RDONLY))
	{
	    $realdir = "$dir/$first12bits";
	}
	else
	{
	    next;
	}

	if ($opt->{head} eq "0")
	{
	    close F;
	    return (\qq{}, -s ("$realdir/$md5"));
	}

	my $lockhandle;
        open($lockhandle,">>$dir/.lock");
	flock($lockhandle,LOCK_EX);

	my $data = "";
	my $offset = 0;
	my $b;
	do {
	    $b = sysread F, $data, 70000000, $offset;
	    last if !defined $b;
	    $offset += $b;
	} while $b > 0;
	close F;

	close($lockhandle);

	if ($opt->{touch})
	{
	    my $now = time;
	    if (!utime $now, $now, "$realdir/$md5.meta") {
		sysopen (F, "$realdir/$md5.meta", O_CREAT|O_RDWR);
		close F;
	    }
	}

	return (\$data, length $data) if md5_hex ($data) eq $md5;
	my $error = "Checksum mismatch: $realdir/$md5";
	warn "$error\n";
	$self->act_on_disk_error($error, $dir);
    }
    $self->{errstr} = "Not found: $md5";
    return undef;
}


sub _store
{
    my $self = shift;
    my $md5 = shift;
    my $dataref = shift;
    my $metaref = shift;
    my @errstr;
    my $errstr;
    my $dirs = $self->{Directories}; # should shuffle this XXX
    my ($first12bits) = $md5 =~ /^(...)/;
    my $try = 0;
    while ($try < ($#$dirs * 2 + 2))
    {
        my $dir = $dirs->[0];

	if ($self->_is_full($dir))
	{
	    $errstr = "write $dir/$first12bits/$md5: No space left on device";
	    next;
	}

	# First time around, try a non-blocking lock on each disk.
	# Second time around, wait for the first disk to be free.

	my $lockhandle;
        open($lockhandle,">>$dir/.lock");
        print STDERR "LOCK: opened file\n" if ($ENV{DEBUG});
	my $lock_non_block = ($try <= $#$dirs) ? LOCK_NB : 0;
        if (not flock($lockhandle, LOCK_EX | $lock_non_block)) {
            close($lockhandle);
            next;
	}

	mkdir "$dir/$first12bits";
	if (!sysopen (F, "$dir/$first12bits/$md5", O_WRONLY|O_CREAT|O_EXCL))
	{
	    $errstr = "create $dir/$first12bits/$md5: $!";
	    $self->act_on_disk_error ($!, $dir);
            close($lockhandle);
	    next;
	}
	my $offset = 0;
	my $b;
	do {
	    $b = syswrite F, $$dataref, length($$dataref)-$offset, $offset;
	    last if !defined $b;
	    $offset += $b;
	} while $offset < length $$dataref;
	if (!defined $b)
	{
	    $errstr = "write $dir/$first12bits/$md5: $!";
	    $self->act_on_disk_error ($!, $dir);
	    close F;
	    unlink "$dir/$first12bits/$md5";
            close($lockhandle);
	    next;
	}
	if (!close F)
	{
	    $errstr = "close $dir/$first12bits/$md5: $!";
	    $self->act_on_disk_error ($!, $dir);
	    unlink "$dir/$first12bits/$md5";
            close($lockhandle);
	    next;
	}
	if (sysopen (M, "$dir/$first12bits/$md5.meta", O_RDWR|O_CREAT))
	{
	    sysseek (M, 0, 2);
	    print M $$metaref;
	    close M;
	}
        close($lockhandle);

	return $md5;
    }
    continue
    {
	push @errstr, $errstr if !grep { $_ eq $errstr } @errstr;
	push @$dirs, shift @$dirs;
	++$try;
    }
    $self->{errstr} = join (", ", @errstr);
    return undef;
}


sub _log
{
    my $self = shift;
    my $c = shift;
    my $message = shift;
    print (scalar(localtime) . " " . $c->peerhost() . " L " . $message . "\n");
}

sub act_on_disk_error
{
    my $self = shift;
    my $error = shift;
    my $dir = shift;
    if ($error =~ /no space left on device/i)
    {
	$self->{node_status}->{dirs}->{$dir}->{status} = "full " . scalar time;
	symlink scalar time, "$dir/full~";
	rename "$dir/full~", "$dir/full";
    }
    else {
	open E, "+>>", "$dir/last_error~";
	flock E, LOCK_EX;
	truncate E, 0;
	print E "$error\n";
	rename "$dir/last_error~", "$dir/last_error";
	close E;
    }
}

sub get_last_errors
{
    my $self = shift;
    for my $dir (@{$self->{Directories}}) {
	if (open E, "<", "$dir/last_error") {
	    $self->{node_status}->{dirs}->{$dir}->{last_error} = scalar <E>;
	    $self->{node_status}->{dirs}->{$dir}->{last_error_time} = (stat E)[9];
	}
    }
}

sub _is_full
{
    my $self = shift;
    my $dir = shift;

    if (!$dir)
    {
	my $dirs = $self->{Directories};
	for (@$dirs) {
	    $self->_is_full ($_) || return 0;
	}
	return 1;
    }

    my $fulltime;
    if ($self->{node_status}->{dirs}->{$dir}->{status} =~ /^full (\d+)/ && $1 > time - 3600)
    {
	return 1;
    }
    if (-l "$dir/full" &&
	($fulltime = readlink ("$dir/full")) &&
	$fulltime > time - 3600)
    {
	$self->{node_status}->{dirs}->{$dir}->{status} = "full $fulltime";
	return 1;
    }
    if ($self->{node_status}->{dirs}->{$dir}->{status} =~ /^ok (\d+)/ && $1 > time - 60)
    {
	return 0;
    }
    if (`df --block-size=1k '$dir'` =~ /^\S+\s+\d+\s+\d+\s+(-?\d+)\s+\d+%/m
	&& $1 < 65536)
    {
	$self->{node_status}->{dirs}->{$dir}->{status} = "full " . scalar time;
	symlink scalar time, "$dir/full~";
	rename "$dir/full~", "$dir/full";
	return 1;
    }
    $self->{node_status}->{dirs}->{$dir}->{status} = "ok " . scalar time;
    return 0;
}

sub _ping_api_host {
    my $self = shift;
    my $ping_url = sprintf('https://%s:%s/arvados/v1/keep_disks/ping',
			   $self->{api_host}, $self->{api_port} || '443');

    my $lwp = LWP::UserAgent->new();

    # verify_hostname is false in development
    $lwp->ssl_opts(verify_hostname => 0);
    $lwp->default_header(
        'Authorization' => "OAuth2 " . $self->{api_auth_token});

    my $dirs = $self->{node_status}->{dirs};
    for my $d (keys %$dirs) {
	my $metadata = $self->_get_keep_dir_metadata($d);

	my $ping_request = {
	    ping_secret      => '',
	    service_port     => $self->{ListenPort},
	    service_ssl_flag => 'false',
	};
	while (my ($key, $val) = each %$metadata) {
	    $ping_request->{$key} = $val;
	}

	# ping the api host
	my $result = $lwp->post($ping_url, $ping_request);
	if ($result->is_success) {
	    my $ping_response = JSON::from_json( $result->decoded_content );
	    if (! $metadata->{node_uuid}) {
		$metadata->{node_uuid} = $ping_response->{uuid};
		$metadata->{dirty} = 1;
	    }
	    if (! $metadata->{ping_secret}) {
		$metadata->{ping_secret} = $ping_response->{ping_secret};
		$metadata->{dirty} = 1;
	    }
	} else {
	    printf STDERR "ping to %s failed: %s\n", (
		$self->{api_host}, $result->status_line);
	}

	$self->_save_keep_dir_metadata($d, $metadata) if $metadata->{dirty};
    }
}

sub _get_keep_dir_metadata {
    my $self = shift;
    my $dir = shift;
    my $metadata;

    # First retrieve any cached metadata in the directory.
    if (-f "$dir/.metadata.yml") {
	$metadata = YAML::LoadFile("$dir/.metadata.yml");
    }

    # If we don't have a filesystem_uuid (no metadata, or
    # it could not be read) try to get it from blkid.
    if (! $metadata->{filesystem_uuid}) {
	my @df = `df $dir`;
	my ($dev) = split /\s+/, $df[1], 2;
	my $uuid = `blkid -s UUID -o value $dev`;
	# If we still don't have a uuid (e.g. running
	# inside a LXC container), make one up.
	if (!$uuid) {
	    $uuid = Data::UUID->to_string( Data::UUID->create() );
	}
	chomp ($metadata->{filesystem_uuid} = $uuid);
	$metadata->{dirty} = 1;   # write this to disk when we're done
    }

    return $metadata;
}

sub _save_keep_dir_metadata {
    my $self = shift;
    my $dir = shift;
    my $metadata = shift;

    delete $metadata->{dirty};
    YAML::DumpFile("$dir/.metadata.yml", $metadata);
}

1;

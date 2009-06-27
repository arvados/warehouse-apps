# -*- mode: perl; perl-indent-level: 4; -*-

package Warehouse::Keep;

use Warehouse;
use HTTP::Daemon;
use POSIX; 
use HTTP::Response;
use Digest::MD5 qw(md5_hex);
use Warehouse;
use Fcntl ':flock';

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

    $self->{dir_status} = {};

    $SIG{HUP} = $SIG{INT} = $SIG{TERM} = sub {
      # Any sort of death trigger results in death of all
      my $sig = shift;
      $SIG{$sig} = 'DEFAULT';
      $Warehouse::Keep::TERM = 1;
      kill 'INT' => keys %Warehouse::Keep::Children;
      warn "$$ killed by $sig\n";
    };

    $self->{ChildLifeTime} = 100;

    $Warehouse::Keep::TotalChildren = 4 * ($#{$self->{Directories}} + 1);
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

    warn "child terminated after $i requests";
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

  # We are going to spawn as many children as we have entries in 
  # $self->{Directories}. This is how we are going to limit having maximum one 
  # concurrent reader/writer per disk. Well, technically this will limit us to one
  # concurrent reader/writer per partition, but for maximum performance there
  # should be no more than 1 (Keep) partition per disk.
  # We'll need a little help from a per-disk lock file in $self->_store as well.

  print STDERR "children at: $Warehouse::Keep::children\n" if ($ENV{DEBUG});
  print STDERR "TotalChildren at: $Warehouse::Keep::TotalChildren\n" if ($ENV{DEBUG});

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
    	    if ($r->url->path eq "/index")
    	    {
    		_index_callback_init ($self);
    		$c->send_response (HTTP::Response->new
    			       (200, "OK", [],
    				\&_index_callback));
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
    	    my $dataref = $self->_fetch ($md5);
    	    if (!$dataref)
    	    {
    		$c->send_response (HTTP::Response->new
    			       (404, "Not found", [], "Not found\n"));
    		last;
    	    }
    	    $c->send_response (HTTP::Response->new
    			   (200, "OK",
    			    ["X-Block-Size", length($$dataref)],
    			    $r->method eq "GET" ? $$dataref : ""));
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

	    my ($verified,$keyid) = $whc->_verify($signedmessage);

	    if (!$verified)
	    {
		$self->_log ($c, "SigFail");
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
		$self->_log ($c, "SigFail ignored");
	    }

	    my $dataref = $self->_fetch ($md5, { touch => 1 });
	    if ($dataref && ($newdata eq "" || $$dataref eq $newdata))
	    {
		$c->send_response (HTTP::Response->new
				   (200, "OK",
				    ["X-Block-Size", length($$dataref)],
				    "$md5\n"));
		next;
	    }

	    if ($dataref)
	    {
		$c->send_response (HTTP::Response->new
				   (400, "Collision",
				    [], "$md5\n"));
		next;
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
		    next;
		}
		if (!defined ($newdata = $self->{whc}->fetch_block ($md5)))
		{
		    $c->send_response (HTTP::Response->new
				       (404, "Data not found in cache",
					[], "Data not found in cache\n"));
		    next;
		}
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
		next;
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
	    if ($c->peerhost() ne $Warehouse::keep_controller_ip)
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
        }
    }
    $c->close if $c;
}


my $_callback_self;
my $_callback_dir;
my @_callback_dirs;
sub _index_callback_init
{
    $_callback_self = shift;
    @_callback_dirs = @ { $_callback_self->{Directories} };
    while (@_callback_dirs &&
	   !(opendir (D, ($_callback_dir = shift @_callback_dirs))))
    { }
}

sub _index_callback
{
    my $file;
    while (1)
    {
	$file = readdir D;
	next if defined ($file) && $file !~ /^[0-9a-f]{32}$/;
	last if defined $file;
	while (1)
	{
	    return undef if !@_callback_dirs;
	    $_callback_dir = shift @_callback_dirs;
	    next unless opendir D, $_callback_dir;
	    last;
	}
    }

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

	my $lockhandle;
        open($lockhandle,">>$dir/.lock");
	flock($lockhandle,LOCK_EX);

	local $/ = undef;
	my $data = <F>;
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

	return \$data if md5_hex ($data) eq $md5;
	warn "Checksum mismatch: $realdir/$md5\n";
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
    my $lockhandle;
    my $try = 0;
    while ($try < ($#$dirs * 2 + 2))
    {
        my $dir = $dirs->[0];

	if ($self->{dir_status}->{$dir} =~ /^full (\d+)/ && $1 > time - 3600)
	{
	    $errstr = "write $dir/$first12bits/$md5: No space left on device";
	    next;
	}

	# First time around, try a non-blocking lock on each disk.
	# Second time around, wait for the first disk to be free.

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
	if (!print F $$dataref)
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
	$self->{dir_status}->{$dir} = "full " . scalar time;
    }
}


1;

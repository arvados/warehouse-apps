# -*- mode: perl; perl-indent-level: 4; -*-

package Warehouse::Server;

use Warehouse;
use CGI;
use HTTP::Daemon;
use HTTP::Response;
use Digest::MD5;
use DBI;
use IO::Handle;


=head1 NAME

Warehouse::Server -- Controller for the storage warehouse.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use Warehouse::Server;

 my $whs = Warehouse::Server->new;
 $whs->run;

=head1 METHODS

=head2 new

 my $whs = Warehouse::Server->new( %OPTIONS );

Creates a new server.  Returns the new object on success.  Dies on
failure.

=head3 Options

=over

=item DatabaseDSN

Reference to an array with database connection info, for example:

  [ "DBI:mysql:database=warehouse;host=dbhost",
    "whserver",
    "DBPASSWORDHERE" ]

=item MapReduceDB

Name of the mapreduce database.  Default is "mapreduce".

=item ListenAddress

IP address to listen on.  Default is "0.0.0.0".

=item ListenPort

Port number to listen on.  Default is 24848.

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
    my Warehouse::Server $self = shift;

    $self->{ListenAddress} = "0.0.0.0"
	if !defined $self->{ListenAddress};

    $self->{ListenPort} = "24848"
	if !defined $self->{ListenPort};

    $self->{MapReduceDB} = "mapreduce"
	if !defined $self->{MapReduceDB};

    $self->{daemon} = new HTTP::Daemon
	( LocalAddr => $self->{ListenAddress},
	  LocalPort => $self->{ListenPort},
	  Reuse => 1,
	);

    $self->{daemon} or die "HTTP::Daemon::new failed";

    $self->{whc} = new Warehouse;

    $self->_reconnect;

    return $self;
}

sub _reconnect
{
    my $self = shift;
    $self->{dbh} = DBI->connect (@ { $self->{DatabaseDSN} });
    $self->{dbh} or die DBI->errstr;
}


=head2 url

  my $url = $whs->url;

Returns the base url of the server (eg. http://1.2.3.4:1234/).

=cut


sub url
{
    my $self = shift;
    return $self->{daemon}->url;
}


=head2 run

  $whs->run;

Listens for connections, and handles requests from clients.

=cut


my $kill = 0;

sub run
{
    my $self = shift;
    local $SIG{INT} = sub { $Warehouse::Server::kill = 1; };
    local $SIG{TERM} = sub { $Warehouse::Server::kill = 1; };
    local $| = 1;

    my $c;
    while (!$kill && ($c = $self->{daemon}->accept))
    {
	my $r;
	while (!$kill && ($r = $c->get_request))
	{
	    print(scalar (localtime) .
		  " " . $c->peerhost() .
		  " R" .
		  " " . $r->method .
		  " " . (map { s/[^\/\w_]/_/g; $_; } ($r->url->path_query))[0] .
		  "\n");

	    $self->_reconnect if !$self->{dbh}->ping;

	    if ($r->method eq "GET" and $r->url->path eq "/list")
	    {
		my $resp = HTTP::Response->new (200, "OK", []);
		$resp->{sth} = $self->{dbh}->prepare
		    ("select mkey, name, keyid from manifests order by name")
		    or die DBI->errstr;
		$resp->{sth}->execute()
		    or die DBI->errstr;
		$resp->{md5_ctx} = Digest::MD5->new;
		$resp->{sth_finished} = 0;
		$resp->content (sub { _callback_manifest($resp) });
		$c->send_response ($resp);
	    }
	    elsif ($r->method eq "POST" and $r->url->path eq "/get")
	    {
		my $sql = "select mkey from manifests where name=?";
		my $sth = $self->{dbh}->prepare ($sql)
		    or die DBI->errstr;
		my $result = "";
		foreach my $name (split ("\n", $r->content))
		{
		    if (0 < length $name)
		    {
			$sth->execute ($name)
			    or die DBI->errstr;
			my ($key) = $sth->fetchrow;
			if ($key)
			{
			    $result .= "200 $key $name\n";
			}
			else
			{
			    $result .= "404  $name\n";
			}
		    }
		}
		my $resp = HTTP::Response->new (200, "OK", [], $result);
		$c->send_response ($resp);
	    }
	    elsif ($r->method eq "GET" and $r->url->path eq "/ping")
	    {
		my $resp = HTTP::Response->new (200, "OK", [], "ack\n");
		$c->send_response ($resp);
	    }
	    elsif ($r->method eq "POST" and $r->url->path eq "/put")
	    {
		my $result;
		my $signedmessage = $r->content;

		# verify signature
		$signedmessage =~ /-----BEGIN PGP SIGNED MESSAGE-----\n.*?\n\n(.*?)\n-----BEGIN PGP SIGNATURE/s;
		my $plainmessage = $1;
		my ($verified,$keyid) = $self->{whc}->_verify($signedmessage);

		if (!$verified)
		{
#		    $self->_log($c, "SigFail");
#		    my $resp = HTTP::Response->new
#			(401, "SigFail",
#			 [], "Signature verification failed.\n");
#		    $c->send_response ($resp);
#		    last;
		    $self->_log($c, "SigFail ignored");
		}

		my $ok = 1;
		foreach my $put (split ("\n", $plainmessage))
		{
		    my ($newkey, $oldkey, $name) = split (/ /, $put, 3);
		    print(scalar (localtime) .
			  " " . $c->peerhost() .
			  " T" .
			  " " . $newkey .
			  " " . $oldkey .
			  " " . $name .
			  "\n");

		    my $sth;
		    my $ok;
		    if (($oldkey eq "NULL") && ($newkey ne '') && ($name ne ''))
		    {
			$sth = $self->{dbh}->prepare
			    ("insert into manifests (mkey, name, keyid) values (?, ?, ?)");
			$ok = $sth->execute ($newkey, $name, $keyid);
		    }
		    elsif ($newkey eq "NULL")
		    { {
			if (!$self->_check_keyid($name,$oldkey,$keyid,$c)) {
				$ok = 0;
				last;
			}
				
			$sth = $self->{dbh}->prepare
			    ("delete from manifests where name=? and mkey=?");

			$ok = $sth->execute ($name, $oldkey)
			    && $sth->rows == 1;
		    } }
		    elsif (($newkey ne '') && ($oldkey ne '') && ($name ne ''))
		    { {
			if (!$self->_check_keyid($name,$oldkey,$keyid,$c)) {
				$ok = 0;
				last;
			}
			$sth = $self->{dbh}->prepare
			    ("update manifests set mkey=?,keyid=? where mkey=? and name=?");
			$ok = $sth->execute ($newkey, $keyid, $oldkey, $name)
			    && $sth->rows == 1;
		    } }
		    else
		    {
			# Error
			$ok = 0;
		    }

		    if ($ok)
		    {
			$result .= "200 $newkey $oldkey $name\n";
		    }
		    else
		    {
			$result .= "500 $newkey $oldkey $name\n";
			$ok = 0;
		    }
		}
		my $resp = HTTP::Response->new
		    ($ok ? 200 : 500,
		     $ok ? "OK" : "Error",
		     [], $result);
		$c->send_response ($resp);
	    }
	    elsif ($r->method eq "GET" and $r->url->path eq "/job/list")
	    {
		my @bindvars;
		my $where = "1=1";
		for (split (/;/, $r->url->query))
		{
		    if (/^outputkey=(.*)/s)
		    {
			$where .= " and output=?";
			push @bindvars, CGI->unescape($1);
		    }
		    elsif (/^inputkey=(.*)/s)
		    {
			$where .= " and input0=?";
			push @bindvars, CGI->unescape($1);
		    }
		    elsif (/^(revision|mrfunction|knobs|nodes)=(.*)/s)
		    {
			$where .= " and $1=?";
			push @bindvars, CGI->unescape($2);
		    }
		    elsif (/^(\d+)-(\d+)$/)
		    {
			$where .= " and id >= $1 and id <= $2";
		    }
		    elsif (/^(\d+)-$/)
		    {
			$where .= " and id >= $1";
		    }
		    elsif (/^(\d+)$/)
		    {
			$where .= " and id = $1";
		    }
		}

		my $resp = HTTP::Response->new (200, "OK", []);
		my $mrdb = $self->{MapReduceDB};
		$resp->{sth} = $self->{dbh}->prepare
		    ("select * from $mrdb.mrjob where $where order by id")
		    or die DBI->errstr;
		$resp->{sth}->execute (@bindvars)
		    or die DBI->errstr;
		$resp->{md5_ctx} = Digest::MD5->new;
		$resp->{sth_finished} = 0;
		$resp->content (sub { _callback_job_list ($resp) });
		$c->send_response ($resp);
	    }
	    elsif ($r->method eq "POST" and $r->url->path eq "/job/new")
	    {
		my $result;
		my $signedmessage = $r->content;

		# verify signature
		$signedmessage =~ /-----BEGIN PGP SIGNED MESSAGE-----\n.*?\n\n(.*?)\n-----BEGIN PGP SIGNATURE/s;
		my $plainmessage = $1;
		my ($verified,$keyid) = $self->{whc}->_verify($signedmessage);

		if (!$verified)
		{
#		    $self->_log($c, "SigFail");
#		    my $resp = HTTP::Response->new
#			(401, "SigFail",
#			 [], "Signature verification failed.\n");
#		    $c->send_response ($resp);
#		    last;
		    $self->_log($c, "SigFail ignored");
		}

		my $mrdb = $self->{MapReduceDB};

		my %jobspec;
		foreach (split (/\n/, $plainmessage))
		{
		    my ($k, $v) = split (/=/, $_, 2);
		    $jobspec{$k} = _unescape($v);
		}
		my @fields = qw(mrfunction
				revision
				inputkey
				knobs);
		if ($jobspec{thawedfromkey})
		{
		    for (@fields) { $jobspec{$_} = ""; };
		    $jobspec{revision} = -1;
		}
		elsif ($jobspec{thaw})
		{
		    # XXX fixme -- should have more error checking here
		    my $sth = $self->{dbh}->prepare ("select * from $mrdb.mrjob where id=?");
		    $sth->execute ($jobspec{thaw});
		    if (my $thaw = $sth->fetchrow_hashref)
		    {
			for (@fields) {
			    $jobspec{$_} = $thaw->{$_};
			}
			$jobspec{inputkey} = $thaw->{input0};
			$jobspec{thawedfromkey} = "".$thaw->{frozentokey};
		    }
		}
		else
		{
		    $jobspec{thawedfromkey} = undef;
		}
		push @fields, qw(nodes
				 photons);
		if (my @missing = grep { !defined $jobspec{$_} } @fields)
		{
		    my $resp = HTTP::Response->new
			(400, "Invalid request",
			 [], "Invalid request: missing fields: @missing");
		    $c->send_response ($resp);
		    last;
		}
		my $ok = $self->{dbh}->do
		    ("insert into $mrdb.mrjob
		      (jobmanager_id, mrfunction, revision, nodes, stepspernode,
		       input0, knobs, thawedfromkey, submittime)
		      values (?, ?, ?, ?, ?, ?, ?, ?, now())",
		     undef,
		     -1,
		     $jobspec{mrfunction},
		     $jobspec{revision},
		     $jobspec{nodes},
		     $jobspec{stepspernode},
		     $jobspec{inputkey},
		     $jobspec{knobs},
		     $jobspec{thawedfromkey});
		my $jobid = $self->{dbh}->last_insert_id (undef, undef, undef, undef)
		    if $ok;
		$ok = $self->{dbh}->do
		    ("insert into $mrdb.mrjobstep
		      (jobid, level, input, submittime)
		      values (?, 0, ?, now())",
		     undef,
		     $jobid, $jobspec{inputkey})
		    if $jobid;
		$self->{dbh}->do
		    ("update $mrdb.mrjob
		      set jobmanager_id=null where id=?",
		     undef, $jobid)
		    if $jobid;
		my $resp = HTTP::Response->new
		    ($jobid ? 200 : 500,
		     $jobid ? "OK" : "Error",
		     [], $jobid);
		$c->send_response ($resp);
	    }
	    elsif ($r->method eq "POST" and $r->url->path eq "/job/freeze")
	    {
		my $result;
		my $signedmessage = $r->content;

		# verify signature
		$signedmessage =~ /-----BEGIN PGP SIGNED MESSAGE-----\n.*?\n\n(.*?)\n-----BEGIN PGP SIGNATURE/s;
		my $plainmessage = $1;
		my ($verified,$keyid) = $self->{whc}->_verify($signedmessage);

		if (!$verified)
		{
#		    $self->_log($c, "SigFail");
#		    my $resp = HTTP::Response->new
#			(401, "SigFail",
#			 [], "Signature verification failed.\n");
#		    $c->send_response ($resp);
#		    last;
		    $self->_log($c, "SigFail ignored");
		}

		my $mrdb = $self->{MapReduceDB};

		my %jobspec;
		foreach (split (/\n/, $plainmessage))
		{
		    my ($k, $v) = split (/=/, $_, 2);
		    $jobspec{$k} = _unescape($v);
		}

		my $status = 500;
		my $sth;
		my $job;
		if ($jobspec{stop}
		    && 0 != $self->{dbh}->do ("update $mrdb.mrjob set jobmanager_id=-1,finishtime=now() where id=? and jobmanager_id is null", undef, $jobspec{id}))
		{
		    $status = 200;
		}
		elsif (($sth = $self->{dbh}->prepare ("select mrjobmanager.pid pid from $mrdb.mrjob left join $mrdb.mrjobmanager on mrjobmanager.id=mrjob.jobmanager_id and mrjob.finishtime is null where mrjob.id=?"))
		       && $sth->execute ($jobspec{id})
		       && ($job = $sth->fetchrow_hashref))
		{
		    if (my $pid = $job->{pid})
		    {
			if ($jobspec{stop})
			{
			    kill "TSTP", $pid;
			}
			else
			{
			    kill "ALRM", $pid;
			}
			$status = 200;
		    }
		    else
		    {
			$status = 400;
			$error = "Specified job is not running.";
		    }
		}
		else
		{
		    $status = 404;
		    $error = "No such job.";
		}
		my $resp = HTTP::Response->new
		    ($status,
		     $status == 200 ? "OK" : "Error",
		     [], $status == 200 ? "OK" : $error);
		$c->send_response ($resp);
	    }
	    else
	    {
		my $resp = HTTP::Response->new
		    (501, "Not implemented",
		     [], "Not implemented.\n");
		$c->send_response ($resp);
	    }
	}
	$c->close;
    }
}

sub _check_keyid 
{
    my $self = shift;
    my $name = shift;
    my $mkey = shift;
    my $keyid = shift;
    my $c = shift;
    $sth = $self->{dbh}->prepare
	("select keyid from manifests where name=? and mkey=?");
    my $ok = $sth->execute ($name, $mkey)
	&& $sth->rows == 1;
    return 0 if (!$ok);
    my $oldkeyid;
    if (my $row= $sth->fetchrow_hashref) {
	$oldkeyid = $row->{keyid};
    } else {
	return 0;
    }
    if (($oldkeyid ne '') && ($oldkeyid ne $keyid)) {
	$self->_log($c, "manifest overwrite failed for $name: $keyid trying to overwrite manifest owned by $oldkeyid");
	return 0;
    }
    return 1;
}

sub _callback_manifest
{
    my $self = shift;
    if ($self->{sth_finished})
    {
	return undef;
    }
    elsif (my @row = $self->{sth}->fetchrow_array)
    {
	my $data = join ("\t", @row) . "\n";
	$self->{md5_ctx}->add ($data);
	return $data;
    }
    else
    {
	$self->{sth_finished} = 1;
	return $self->{md5_ctx}->hexdigest . "\n";
    }
}

sub _callback_job_list
{
    my $self = shift;
    if ($self->{sth_finished})
    {
	return undef;
    }
    elsif (my $job = $self->{sth}->fetchrow_hashref)
    {
	
	my $data = join ("\n",
			 map {
			     my $v = $job->{$_};
			     $v =~ s/\\/\\\\/g;
			     $v =~ s/\n/\\n/g;
			     $_ = "inputkey" if $_ eq "input0";
			     $_ = "outputkey" if $_ eq "output";
			     $_."=".$v;
			 } keys %$job)
	    . "\n\n";
	$self->{md5_ctx}->add ($data);
	return $data;
    }
    else
    {
	$self->{sth_finished} = 1;
	return $self->{md5_ctx}->hexdigest . "\n";
    }
}


my %_unescapemap = ("n" => "\n",
		    "\\" => "\\");
sub _unescape
{
    local $_ = shift;
    s/\\(.)/$_unescapemap{$1}/ge;
    $_;
}

sub _log
{
    my $self = shift;
    my $c = shift;
    print (scalar(localtime) . " " . $c->peerhost() . " L " . @_ . "\n");
}

1;

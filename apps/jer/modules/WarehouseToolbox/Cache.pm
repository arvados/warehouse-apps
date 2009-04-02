package WarehouseToolbox::Cache;
use strict;
use warnings;
use DBI;
use Digest::MD5 qw(md5_hex);
use base 'Exporter';

our @EXPORT = qw(get_hashentry_id get_manifest_id get_resultset_id tag_manifest_for_fetch tag_resultset_for_fetch get_manifests_of get_manifest get_resultset);
our @EXPORT_OK = qw(update_hashentry update_manifest new_hashentry new_manifest tag_gc_safe tag_gc_unsafe find_waiting_tasks),
	qw(remove_hashentry remove_manifest add_to_resultset remove_from_resultset touch_resultset touch_hashentry touch_manifest);


sub get_manifest_id { get_hashentry_id(@_); }
sub update_manifest { update_hashentry(@_); }
sub new_manifest { new_hashentry(@_); }
sub remove_manifest { remove_hashentry(@_); }
sub touch_manifest { touch_hashentry(@_); }


require '../whcache-db-auth.pl' 
	or die ("Configuration file not found.  Please edit the whcache-db-auth.pl file before using WarehouseToolbox::Cache.");

db_connect();

# db_connect() or die "unable to connect to WarehouseToolbox::Cache database";
sub db_connect { return ($dbh = DBI->connect(main::dsn_vars()); }

# &db_disconnect or warn "WarehouseToolbox::Cache database disconnection was unsuccessful";
sub db_disconnect {	return ($dbh->disconnect()); }

# indicate that a hash requires updating
# tag_manifest_for_fetch($manifest_id);
sub tag_manifest_for_fetch {	
	my $id = shift;
	if (!$id) {
		my $sql = q{ insert into v_hashentries (hash, request_fetch) values (?, 'Y'); };
	} else {
		my $sql = q{ update v_hashentries set request_fetch='Y' where hash=?; };
	}
	my $uh = $dbh->prepare( $sql );
	$uh->execute( $key ) or die "Insert/update failed: $DBI::errstr";
	$uh->finish;
	return 1;
}

# tag_resultset_for_fetch($resultset_hash_key);
sub tag_resultset_for_fetch {
	return undef unless ($_[0] =~ /([0-9a-f]{32})/);
	my $set = $1;
	my $id = get_resultset_id($set);
	return undef unless $id;
	my $uh = $dbh->prepare( q{ update v_resultsets set request_fetch='Y' where handle=?; } );
	$uh->execute( $set ) or die "Update failed: $DBI::errstr";
	$uh->finish;
	return 1;
}

# my $id = get_hashentry_id($manifest_hash_key);
sub get_hashentry_id {
	return undef unless ($_[0] =~ /([0-9a-f]{32})/);
	my $key = $1;
	my $sth = $dbh->prepare( q{ select id from v_hashentries where hash = ?; } );	
	$sth->execute( $key );
	my ($id) = $sth->fetchrow_array();
	$sth->finish;
	return $id;
}

# my $id = get_resultset_id($resultset_hash_key);
sub get_resultset_id {
	return undef unless ($_[0] =~ /([0-9a-f]{32})/);
	my $set = $1;
	my $sth = $dbh->prepare( q{ select id from v_resultsets where handle = ?; } );
	$sth->execute( $set );
	my ($id) = $sth->fetchrow_array();
	$sth->finish;
	return $id;
}

# update_manifest( { id=>100, sanity=>'Y', ...})
sub update_hashentry {
	my %newset = %{$_[0]};
	$newset{id} ||= new_manifest($newset{hash});
	return undef unless ($newset{id});
	my $sql = 'update v_hashentries set';
	my @values;
	for ( qw(entry_type sanity request_fetch data_size) ) {
		if ($newset{$_}) {
			$sql.= " $_=?";
			push(@values, $newset{$_});
		}
	}
	$sql.= ' where id=?;';
	my $sth = $dbh->prepare( $sql );
	$sth->execute( @values, $newset{id} ) or die "Update failed: $DBI::errstr";
	$sth->finish;
	return $id;
}

# $id = new_hashentry($hashkey);
sub new_hashentry {
	my $key = shift;
	return undef unless $key =~ (/^[0-9a-f]{32}$/);
	$dbh->do( q{ insert into v_hashentries (hash) values (?); }, $key) or return undef;
	my $sth = $dbh->prepare( q{ select id from v_hashentries where hash=?; });
	$sth->execute($key);
	my ($id) = $sth->fetchrow_array();
	$sth->finish;
	return $id || 0;
}

# remove_hashentry($hashkey);
# removes a hashentry from the database
sub remove_hashentry {
	my $hashid = int shift;
	my $sth = $dbh->prepare( q{ delete from v_hashentries where id=?; } );
	$sth->execute( $hashid ) or return 0;
	$sth->finish;
	my $sth = $dbh->prepare( q{ delete from v_references where manifest=?; } );
	$sth->execute( $hashid );
	$sth->finish;
	return 1;
}

# add_to_resultset ($resultsetid, $hashid [, $hashid, ...]);
sub add_to_resultset {
	my $setid = shift;
	my $sth = $dbh->prepare( q{ insert into v_references (manifest, result_set, request_fetch) values (?, ?, 'N'); } );
	while (shift) {
		$sth->execute(int $_, int $setid) or warn "Insert failed: $DBI::errstr";
		$sth->finish();
	}
	return 1;
}	

# remove_from_resultset ($resultsetid, $hashid [, $hashid, ...]);
sub remove_from_resultset {
	my $setid = shift;
	my $sth = $dbh->prepare( q{ delete from v_references where manifest=? and result_set=?; } );
	while (shift) {
		$sth->execute(int $_, int $setid) or warn "Delete failed: $DBI::errstr";
		$sth->finish;
	}
	return 1;
}

# $resultset_id = get_restultset_id(@manifest_hashes);
sub get_resultset_id {
	my $handle = md5_hex(join(',',sort @_));
	my $sth = $dbh->prepare( q{ select id from v_resultsets where handle=?; } );
	$sth->execute(int $handle) or die "SELECT failed: $DBI::errstr";
	my ($id) = $sth->fetchrow_array();
	$sth->finish;
	return $id if $id;
	$sth = $dbh->prepare( q{ insert into v_resultsets (handle, request_fetch) values(?, 'N'); select last_insert_id(); } );
	$sth->execute($handle);
	($id) = $sth->fetchrow_array();
	$sth->finish;
	return $id;
}

# updates the last_fetch date on a manifest or hash key
# touch_hashentry($id) or warn "unable to update last_fetch for ID=$id"; # updates to mysql NOW()
# touch_hashentry($id, $mysql_datestring);
sub touch_hashentry {
	my $id = int shift;
	my $when = shift;
	return 0 unless ($id > 0);
	my $sth = $dbh->prepare( q{ update v_hashentries set last_fetch=ifnull(?, now()) where id=?; } );
	$sth->execute( $id, $when ) or die "Update failed: $DBI::errstr";
	$sth->finish;
	return 1;
}

# touch_resultset($id) or warn "unable to update last_fetch for ID=$id"; # updates to mysql NOW()
# touch_resultset($id, $mysql_datestring);
sub touch_resultset {
	my $id = int shift;
	my $when = shift;
	return 0 unless ($id > 0);
	my $sth = $dbh->prepare( q{ update v_resultsets set last_fetch=ifnull(?, now()) where id=?; } );
	$sth->execute( $id, $when ) or die "Update failed: $DBI::errstr";
	$sth->finish;
	return 1;
}

# tag_gc_safe($manifest_id);
sub tag_gc_safe {
	my $id = int shift;
	die ("not a valid manifest id: $id") unless ($id > 0);
	$dbh->do( q{ update v_hashentries set last_gcsafe=now() gcsafe='Y' where id=?; }, $id);
		or die "Update failed: $DBI::errstr";
	$sth->finish;
	return 1;
}	

# tag_gc_unsafe($manifest_id);
sub tag_gc_unsafe {
	my $id = int shift;
	die ("not a valid manifest id: $id") unless ($id > 0);
	$dbh->do( q{ update v_hashentries set last_gcsafe=now() gcsafe='N' where id=?; }, $id);
		or die "Update failed: $DBI::errstr";
	$sth->finish;
	return 1;
}

# $manifest_id_array = get_manifests_of($resultset_id);
sub get_manifests_of {
	my $id = int shift;
	die ("not a valid manifest id: $id") unless ($id > 0);
	my $sth = $dbh->prepare( q{ select manifest from v_references where result_set=?; });
	$sth->execute($id);
	my ($man, @mans);
	$sth->bind_col(1, \$man);
	while ($sth->fetch) {
		push @mans, $man;
	}
	$sth->finish;
	return [@mans];
}

# $manifest_hashref = get_manifest($manifest_id);
sub get_manifest {
	my $id = int shift;
	die ("not a valid manifest id: $id") unless ($id > 0);
	my $sth = $dbh->prepare( q{ select * from v_hashentries where id=?; });
	$sth->execute($id);
	my $hr = $sth->fetchrow_hashref();
	$sth->finish;
	return $hr;
}
	
# $resultset_hashref = get_resultset($resultset_id);
sub get_resultset {
	my $id = int shift;
	die ("not a valid resultset id: $id") unless ($id > 0);
	my $sth = $dbh->prepare( q{ select * from v_resultsets where id=?; });
	$sth->execute($id);
	my $hr = $sth->fetchrow_hashref();
	$sth->finish;
	return $hr;
}

# update_resultset( { id=>100, request_fetch=>'Y', ...})
sub update_resultset {
	my $newset = shift;
	$newset->{id} ||= get_resultset_id($newset->{handle});
	return undef unless ($newset->{id});
	my $sth = $dbh->prepare( q{ select * from v_resultsets where id=?; } );
	$sth->execute($newset->{id});
	my $oldset = $sth->fetch_hashref();
	$sth->finish;
	my %values = map { $_ => $newset{$_} || $oldset{$_} } (keys %{$oldset});
	$sth = $dbh->prepare( q{ update v_resultsets set request_fetch=? job_count=? job_time=? where id=? } );
	$sth->execute( $values{request_fetch}, $values{job_count}, $values $newset->{id} ) or die "Update failed: $DBI::errstr";
	$sth->finish;
	return $id;
}

# $tasks = find_waiting_tasks();
# for (@{$tasks}) { print $_->{id} . '=' . $_->{type}; }
sub find_waiting_tasks {
	my ($tasks = [], $id);
	my $sth = $dbh->prepare( q{ select id from v_resultsets where request_fetch='Y'; } );
	$sth->execute();
	$sth->bind_col(1, \$id);
	while ($sth->fetch) {	push @{tasks}, {id=>$id, type=>'resultset'; };
	$sth->finish;
	$sth = $dbh->prepare( q{ select id from v_hashentries where request_fetch='Y' and entry_type='MAN'; } );
	$sth->execute();
	$sth->bind_col(1, \$id);
	while ($sth->fetch) {	push @{tasks}, {id=>$id, type=>'manifest'; };
	$sth->finish;
	return $tasks;
}

# exported functions


1;



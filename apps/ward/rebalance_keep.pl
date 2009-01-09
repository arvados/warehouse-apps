#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;

use Warehouse;


my $MAX_NODE_POSITION = 3;

my %opt;
map { $opt{$1} = $2 if /(.+?)=(.*)/s } @ARGV;

# Putting in a newline as a separator for knob keypairs is unwieldy on the
# command line. Instead, let's just accept a space as separator and turn it
# into a proper newline here, which is what the new_job warehouse function
# expects. If you need to include spaces in knobs, submit the knobs as
# separate opts like FOO="bar baz" instead of knobs="FOO=bar baz".
$opt{'knobs'} =~ s/ /\n/g;

my $whc;
$whc = new Warehouse ($opt{warehouse_name}
		      ? (warehouse_name => $opt{warehouse_name})
		      : ());

my $hostname = `hostname`;
chomp($hostname);
$hostname =~ s/\..*$//;

print STDERR "Local hostname: $hostname\n\n" if ($ENV{DEBUG_KEEP});

while (<STDIN>) {
	chomp();
	my $filename = $_;
	next if ($filename =~ /\.meta|^$/);
	if (! -f $filename) {
		print STDERR "$filename was not found on the local filesystem. Please make sure you provide a full path.\n";
		next;
	}
	my $hash = $filename;
	$hash =~ s/^.*\/([^\/]+)$/$1/;

	print STDERR "Processing $hash:\n";

	my ($keeps_arrayref, @probeorder) = $whc->_hash_keeps(undef, $hash);
	
	my $cnt = 0;
	foreach my $t (@probeorder) {
		my $tmp = @{$keeps_arrayref}[$t];
		$tmp =~ s/:.*$//;
		if ($tmp eq $hostname) {
			print STDERR "Found $hostname at pos $cnt\n";
			if ($cnt > $MAX_NODE_POSITION) {
				# Push blocks to higher-priority nodes. Note that the following comment
				# is not always correct, if the nodes in probeorder 0 and 1 are not
				# there, Keep will automatically store to the next node(s) in the
				# order, and not complain.
				print STDERR "Pushing block to correct nodes (@{$keeps_arrayref}[$probeorder[0]] and @{$keeps_arrayref}[$probeorder[1]])...\n";
				# by reading in the file from disk we avoid the warehouse library
				# having to try a lot of keep nodes to find the data.
				my $data = '';
				open(my $fh,"<",$filename);
				read($fh, $data, -s $fh);
				close($fh);
				my $diskhash = Digest::MD5::md5_hex ($data); 
				if ($hash ne $diskhash) {
					print STDERR "ERROR: data corruption: md5sum of $filename is $diskhash\n";
				}
				my ($hash_with_hints, $nnodes) = $whc->store_in_keep(dataref => \$data, nnodes => 2);
				if (!defined($hash_with_hints) or !defined($nnodes)) {
					print STDERR "Something went wrong writing to Keep. Aborting.\n";
					exit(1);
				}
				print STDERR "returned: $hash_with_hints on $nnodes\n";
				# Now verify we can get the data from those nodes
				# Just in case, temporarily rename the local copy so that keep won't find it anymore
				rename($filename,"$filename-TMP");
				print STDERR "Verifying...\n";
				my $dataref = $whc->fetch_from_keep ($hash, { nnodes => 2 });
				if (!defined $dataref) {
					print STDERR "ERROR: could not verify $hash on 2 primary nodes\n";
					rename("$filename-TMP","$filename");
				} else {
					unlink("$filename-TMP");
					unlink("$filename.meta");
				}
			} else {
				print STDERR "Position OK for this block\n" if ($ENV{DEBUG_KEEP});
	
			}
			last;
		}
		$cnt++;
	}
}


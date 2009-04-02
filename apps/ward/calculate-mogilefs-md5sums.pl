#!/usr/bin/perl

# This script calculates md5sums for all files in mogilefs.
#
# It requires one filename as argument, pointing to a file that does not exist
# yet, into which the output of the script will be saved.
#
# The script optionally takes a second filename as argument, which can contain
# (partial) output from a previous run of this script.
#
# It outputs to stdout, in the format (one entry per line):
#
#   INODE-MTIME-FILENAME-MD5SUM
#
# Ward Vandewege, 2009-01-30

my %files = {};

if (!$ARGV[0] || -e $ARGV[0]) {
	print STDERR "The first argument must be a filename that does not exist yet. The output of the script will be saved there.\n";
	exit(1);
}

if ($ARGV[1] && -f ($ARGV[1])) {
	open(FILE, "<", $ARGV[1]);
	while (<FILE>) {
		chomp;
		my @tmp = split(/-/);
		if (-f $tmp[2]) { # only keep files that actually exist
			$files{$tmp[2]}{inode} = $tmp[0];
			$files{$tmp[2]}{mtime} = $tmp[1];
			$files{$tmp[2]}{md5sum} = $tmp[3];
		}
	}
	close(FILE);
} else {
	print "No input file specified on command line, or argument specified is not a file. Starting anew!\n";
}

my @files = `find -L /mogdata/dev* -type f |grep 'fid\$'`;

open(OUTPUTFILE, ">", $ARGV[0]);
foreach my $file (@files) {
	chomp($file);
	my $redo = 0;
	my @stat = stat($file);
	if (exists($files{$file})) {
		if (($stat[1] ne $files{$file}{inode}) || ($stat[9] ne $files{$file}{mtime})) {
			print STDERR "$file has been modified\n" if ($ENV{DEBUG});
			$redo = 1;
		} else {
			print OUTPUTFILE "$files{$file}{inode}-$files{$file}{mtime}-$file-$files{$file}{md5sum}\n";
		}
	} else {
		print STDERR "$file is new\n" if ($ENV{DEBUG});
		$redo = 1;
	}
	print OUTPUTFILE $stat[1] . '-' . $stat[9] . "-$file-" . `md5sum $file|cut -d' ' -f1` if ($redo);
}
close(OUTPUTFILE);


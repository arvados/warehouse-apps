#!/usr/bin/perl


if (!$ARGV[0] || ! -f $ARGV[0]) {
  print STDERR "The first argument must be a path to a file that contains the md5sums marked for deletion.\n";
  exit(1);
}

if (!$ARGV[1] || ! -f $ARGV[1]) {
  print STDERR "The second argument must be a path to a file that contains the output of the\ncalculate-mogilefs-md5sum.pl script from a run on the local host.\n";
  exit(1);
}

if (!$ARGV[2] || -e $ARGV[2]) {
  print STDERR "The third argument must be a filename that does not exist yet. The output of the script will be saved there.\n";
  exit(1);
}


my %to_delete = {};
my %mogfiles = {};

open(FILE, "<", $ARGV[0]);
while (<FILE>) {
  chomp;
	$to_delete{$_} = $_;
}
close(FILE);

open(FILE, "<", $ARGV[1]);
while (<FILE>) {
  chomp;
  my @tmp = split(/-/);
  if (-f $tmp[2]) { # only keep files that actually exist
    $mogfiles{$tmp[3]}{inode} = $tmp[0];
    $mogfiles{$tmp[3]}{mtime} = $tmp[1];
    $mogfiles{$tmp[3]}{filename} = $tmp[2];
  }
}
close(FILE);

open(OUTPUT,">", $ARGV[2]);
foreach (keys %to_delete) {
	if (exists($mogfiles{$_})) {
		print OUTPUT "rm -f $mogfiles{$_}{filename}\n";
	}
}
close(OUTPUT);

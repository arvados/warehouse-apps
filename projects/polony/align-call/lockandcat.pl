#!/usr/bin/perl -w

use strict; 
use Fcntl ':flock';

open (LOCKFILE, ">>imagelockfile") or die "imagelockfile: $!";
flock (LOCKFILE, LOCK_EX);
until ( eof(STDIN) ) {
    read(STDIN, $_, 1048576*16);
    if (eof (STDIN)) {
	flock (LOCKFILE, LOCK_UN);
	close (LOCKFILE);
    }
    print STDOUT $_;
}

# arch-tag: Tom Clegg Tue Mar 20 20:12:17 PDT 2007 (align-call/lockandcat.pl)

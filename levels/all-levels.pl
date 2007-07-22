#!/usr/bin/perl

#@files = split(/\n/, `find | grep tif`);
#@files = split(/\n/, <STDIN>);
#foreach $file (@files) {
while (<STDIN>) {
    chomp;
    $file = $_;
    $stats = `levels -i -t $file`;
    chomp $stats;
    print "# $file\t$stats\n";
    # uncomment to do histograms too
    $result = `levels -t $file`;
    print $result;
}


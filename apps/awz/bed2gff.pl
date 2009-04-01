#!/usr/bin/perl
 	
 	use strict;
 	
 	my %addslashes = qw(A A
 	                    C C
 	                    G G
 	                    T T
 	                    M A/C
 	                    R A/G
 	                    W A/T
 	                    S C/G
 	                    Y C/T
 	                    K G/T
 	                    V A/C/G
 	                    H A/C/T
 	                    D A/G/T
 	                    B C/G/T
 	                    N A/C/G/T
 	                    X A/C/G/T);
 	
 	while (<>)
 	{
 	    chomp;
 	    my @in = split;
 	    my $bp = $addslashes{uc substr($in[3],2,1)};
	    my $ref = substr($in[3],0,1);
 	    print join ("\t",
 	                $in[0],
 	                "maq", "SNP",
 	                $in[2], $in[2],
 	                ".", "+", ".",
 	                "alleles $bp;ref_allele $ref");
 	    print "\n";
 	}


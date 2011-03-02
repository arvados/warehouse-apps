package ProbCluster;
sub prob_of_cluster
{	
	( my $p, my $n, my $k ) = @_;
	my $lambda = $n * $p;
	my $term;
	my $sum = 0;

	#print "n = $n, k = $k, p = $p, lambda = $lambda\n";
	if ($n > 20 and $p < 0.05) # Use Poisson
	{		
		# Calculate cumulative Poisson probability: P_j=P_{j-1}*lambda/j.
    		# i=0
		$term = exp( -$lambda );
		$sum  = 1 - $term;
		foreach my $i ( 1 .. ( $k - 1 ) )
		{		  
		  $term *= ($lambda / $i);
		  #print "i = $i, term = $term, sum = $sum\n";
		  $sum -= $term;				  
		}
	}
	else # Use binomial
	{
		#print "p = $p, n = $n, k = $k\n";
		$term = (1-$p) ** $n;
		$sum  = 1 - $term;
		foreach my $i ( 1 .. ( $k - 1 ) )
		{
		  $term *= ( (($n-$i+1) * $p) / ($i * (1-$p)) );
		  $sum -= $term;
		  #print "sum = $sum, term = $term\n";
		}		
	}
	# This is the probability for k or more events out of n experiments	
	
	if ($sum < 0)
	{
		$sum = 0;
	}
  	return $sum;
}

1;

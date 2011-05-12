package FindClustersOneWay;
use strict;
use ProbCluster;

my $c_handle = \*STDOUT;
my @mm;
my @mm_genome_address;
my @mm_trace_address;
my @ind;
my $total_prob;
my @where;
my $reverse_count;
my $mm_count;
my $len;
my $pvalue;
my $th;
#my $output_file;
my $a_name;
my $g_name;
my $control;
my $number_of_clusters;
my $strand;

sub find_clusters_by_length
{
	(my $mm_ref_q, my $mm_ref_s, my $ind_ref, $a_name, $g_name, my $prob, $strand, $control, $mm_count, $len, my $cmd_line_ref) = @_;
	@mm = @$mm_ref_s;
	@mm_genome_address = @$mm_ref_s;
	@mm_trace_address = @$mm_ref_q;
	@ind = @$ind_ref;
	my @cmd_line = @$cmd_line_ref;
	#( $output_file, $pvalue, $th ) = @cmd_line;
	($pvalue, $th ) = @cmd_line;

	#	print "a name = $a_name, g name = $g_name\n";
	#   print "mm: size = ", scalar @mm, ", @mm, ind: @ind\n";
	#	print "prob = $prob\n";
	#	print "pvalue = $pvalue, th = $th\n";

	#	print "name = $cluster_name\n";
	my $i;
	my $j;
	my $jmin;
	my $best_j;
	$i          = 0;
	$best_j     = -1;
	$total_prob = 1;
	@where      = ();
	$number_of_clusters = 0;	
	while ( $i < $#mm )
	{
		$jmin = max( $best_j, $i + $th - 2 );		
		for ( $j = $#mm ; $j > $jmin ; $j-- )
		{			
			if (($j - $i + 1) < $th)  {next;}
			if (($ind[$j] - $ind[$i] + 1) > ($j - $i + 1)) {next;}
			my $cprob = ProbCluster::prob_of_cluster( $prob, $mm[$j] - $mm[$i] + 1, $j - $i + 1 );
			if ($cprob < 0)
			{
				print "prob = $cprob, p = $prob, n = ", $mm[$j] - $mm[$i] + 1, ", k = ", $j - $i + 1, "\n";
			}
			if ( $cprob < $pvalue )
			{				
				push( @where, ( max( $i, $best_j + 1 ) .. $j ) );
				if ($i > $best_j)
				{
					$total_prob *= $cprob; # The total_prob is an upper bound because it does not include the probability of extended windows
					$number_of_clusters++;
				}
				$best_j = $j;
				last;
			}
		}
		$i++;
	}
	if ($number_of_clusters > 0) {write_cluster();}
}

sub max
{
	if ( $_[0] < $_[1] ) { return $_[1] }
	else { return $_[0] }
}

sub write_cluster
{
	my $cluster_name;
	if ($control)
	{
		print $c_handle "Found cluster: Control\n";
		#$cluster_name =	">>" . $output_file . "_" . $pvalue . "_" . $th . "_control.txt";
	}
	else
	{
		print $c_handle "Found cluster: Real\n";
		#$cluster_name =	">>" . $output_file . "_" . $pvalue . "_" . $th . "_real.txt";
	}
	#open( $c_handle, $cluster_name );
	
	if ($strand eq '+')
	{
		print $c_handle "Strand = Plus\n";
		print $c_handle "A name = $a_name\n";
		print $c_handle "G name = $g_name\n";
	}
	else
	{
		print $c_handle "Strand = Minus\n";
		print $c_handle "T name = $a_name\n";
		print $c_handle "C name = $g_name\n";
	}
	print $c_handle "Total probability = $total_prob, $number_of_clusters cluster";
	if ($number_of_clusters > 1) {print $c_handle "s\n";} else {print $c_handle "\n";}	
	my $str_format = '';
	foreach my $x (@where) { $str_format .= "%12d "; }
	$str_format .= "\n";
	#print $c_handle "Edited MM serial no.    : ";
	my @where1base;
	foreach my $i ( 0 .. $#where ) { $where1base[$i] = $where[$i] + 1; }
	#printf $c_handle $str_format , @where1base;
	print $c_handle "All genome locations: ";
	printf $c_handle $str_format , @mm_genome_address[@where];
	print $c_handle "All trace locations : ";
	printf $c_handle $str_format , @mm_trace_address[@where];
	print $c_handle "Total length: $len, Direct mismatches: ", scalar(@mm), ", All mismatches: $mm_count\n";
	print $c_handle "End cluster\n\n";

	#close($c_handle);
}

1;

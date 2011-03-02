package ProcessAlignmentOneWay;
use strict;

use FindClustersOneWay;

my %comp = {'a' => 't', 't' => 'a', 'g' => 'c', 'c' => 'g'};

sub process_alignment_by_length
{
	my $hsp_ref      = shift;
	my $hsp          = $$hsp_ref;
	my $query_name   = shift;
	my $hit_name     = shift;
	my $cmd_line_ref = shift;
	my $len = int( ( $hsp->length('query') + $hsp->length('hit') ) / 2 );

	my $strand;
	my $factor;
	my $q_start;
	my $s_start;
	if ( $hsp->strand('query') == $hsp->strand('hit') )
	{	
		$strand = '+';
		$factor = 1;
		$q_start  = $hsp->start('query');
		$s_start  = $hsp->start('subject');
	
	}
	else
	{		
		$strand = '-';
		$factor = -1;
		$q_start  = $hsp->end('query');
		$s_start  = $hsp->end('subject');
		#print "Alignement $query_name<=>$hit_name between different strands!!!\n";
		#return;
	}

	my $orig = 'g';
	my $orig_comp = 'c';
	my $edited = 'a'; 
	my $edited_comp = 't';

	my $str1      = $hsp->query_string;
	my $str2      = $hsp->hit_string;
	my $alignment = $hsp->homology_string;

	my @s1 = split( //, $str1 );
	my @s2 = split( //, $str2 );

	my @mm_ag_s = ();
	my @mm_ga_s = ();
	my @mm_tc_s = ();
	my @mm_ct_s = ();
	my @mm_ag_q = ();
	my @mm_ga_q = ();
	my @mm_tc_q = ();
	my @mm_ct_q = ();
  	my @ag_ind = ();
	my @ga_ind = ();
	my @tc_ind = ();
	my @ct_ind = ();

	my $count_mm = 0;
	my $q_gaps   = 0;
	my $s_gaps   = 0;
	my $ag_count = 0;
	my $ga_count = 0;	
	my $tc_count = 0;
	my $ct_count = 0;
	while ( $alignment =~ /( )/g )
	{
		my $p = ( pos $alignment ) - 1;
		if ( $s1[$p] eq '-' )
		{
			$q_gaps++;
			next;
		}
		if ( $s2[$p] eq '-' )
		{
			$s_gaps++;
			next;
		}
		# query='t', subject='c'
		if ( $s1[$p] eq $edited_comp and $s2[$p] eq $orig_comp )
		{		
			push( @mm_tc_q, $q_start + $p - $q_gaps );
			push( @mm_tc_s, $s_start + $factor * ($p - $s_gaps) );
			push( @tc_ind, $count_mm);
			$tc_count++;
		}
		# query='c', subject='t'
		if ( $s2[$p] eq $edited_comp and $s1[$p] eq $orig_comp )
		{
			push( @mm_ct_q, $q_start + $p - $q_gaps );
			push( @mm_ct_s, $s_start + $factor * ($p - $s_gaps) );
			push( @ct_ind, $count_mm);
			$ct_count++;
		}		
		# query='a', subject='g'
		if ( $s1[$p] eq $edited and $s2[$p] eq $orig )
		{
			push( @mm_ag_q, $q_start + $p - $q_gaps );
			push( @mm_ag_s, $s_start + $factor * ($p - $s_gaps) );
			push( @ag_ind, $count_mm);
			$ag_count++;
		}
		# query='g', subject='a'
		if ( $s2[$p] eq $edited and $s1[$p] eq $orig )
		{
			push( @mm_ga_q, $q_start + $p - $q_gaps );
			push( @mm_ga_s, $s_start + $factor * ($p - $s_gaps) );
			push( @ga_ind, $count_mm);
			$ga_count++;
		}
		$count_mm++;
	}	
	
	my $prob_real;
	my $prob_control;
	if ($strand eq '+')
	{
		$prob_real    = ($ct_count+$tc_count+$ga_count) / ( 3 * $len );
		$prob_control = ($ct_count+$tc_count+$ag_count) / ( 3 * $len );		
	}
	else
	{
		$prob_real    = ($ct_count+$ag_count+$ga_count) / ( 3 * $len );
		$prob_control = ($tc_count+$ag_count+$ga_count) / ( 3 * $len );		
	}
	#print "len = $len, tc count = $tc_count, prob = $prob_real\n";

	# Real	
	if ($strand eq '+')
	{
		FindClustersOneWay::find_clusters_by_length( \@mm_ag_q, \@mm_ag_s, \@ag_ind, $query_name,
			$hit_name, $prob_real, $strand, 0, $count_mm, $len, $cmd_line_ref );
	}
	else
	{
		FindClustersOneWay::find_clusters_by_length( \@mm_tc_q, \@mm_tc_s, \@tc_ind, $query_name,
			$hit_name, $prob_real, $strand, 0, $count_mm, $len, $cmd_line_ref );
	}
	# Control
	if ($strand eq '+')
	{
		FindClustersOneWay::find_clusters_by_length( \@mm_ga_q, \@mm_ga_s, \@ga_ind, $hit_name,
			$query_name, $prob_control, $strand, 1, $count_mm, $len, $cmd_line_ref );
	}
	else
	{
		FindClustersOneWay::find_clusters_by_length( \@mm_ct_q, \@mm_ct_s, \@ct_ind, $hit_name,
				$query_name, $prob_control, $strand, 1, $count_mm, $len, $cmd_line_ref );
	}	
}

1;
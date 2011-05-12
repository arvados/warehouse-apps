# measures the highest number of nodes in use throughout the job array
# timestamp max_node_usage (void)
sub max_node_usage {
	my $maxstack = 0;
	for (1 .. $job_count) {		
		if ($debuggery) { print "check at ".$job_list->{$job_list_startorder[$_]}->{starttime}. " {\n"; }
		my $stacksize = node_usage($job_list->{$job_list_startorder[$_]}->{starttime});		
		$maxstack = $stacksize unless ($maxstack > $stacksize);
		if ($debuggery) {
			print "} stack size is = $stacksize\n";
			# if ($stacksize>40) { die("Node Limiter Exeeded"); }
		}
	}
	return $maxstack;
}
	
# returns the number of nodes used at a given timestamp
# timestamp node_usage (timestamp)
sub node_usage {
	my $at_time = shift;
	my $maxstack = 0;
	for (values %$job_list) {
		if ($at_time >= $_->{starttime} && $at_time < $_->{finishtime}) {
			$maxstack+=$_->{nodes};
			print "\tjob ".$_->{id}." has ".$_->{nodes}." nodes and runs from ".$_->{starttime}." to ".$_->{finishtime}."\n";
		}
	}
	return $maxstack;
}






WORD: while (@words) {
    my $word = shift (@words);
    
    # First take care of the case where a single string is longer
    # than the width
    
    if (($font->width() * length($word)) > $width ) {
       
        # Divide the string in two and push the two words 
        # back on the list

        my $length =  int($width/$font->width());
        my $front = substr($word, 0, $length);
        my $remainder = substr($word, $length+1, 
                               length($string)-1);
        $word = $front;
        unshift @words, $remainder;
    }
    
    if ((($font->width() * length($word)) + $w) > $width ) {
        
        # Start a new line
 
        $cx = $x1;                                   
        $cy = $starty + $font->height();  # Move the current y pt
        $starty = $cy;
 
        $dy = $dy + $ddy * ($cy - $y1);
        $w = 0;
        
        # Move to next word if the line starts with a space

        if ($word eq ' ') {
            next WORD;
        }
    }
    
    # Now draw each character individually
    
    my @chars = split '', $word;   
    push @chars, ' ';             # Push a space on the end

    foreach my $char (@chars) {
        $img->char($font, $cx, $cy, $char, $white);
        
        # Move the current point
 
        $w = $w + $font->width();
        $cx = $cx + $font->width();
        $cy = $starty + int($w * $dy);
    } 
}

# Write the image as a PNG

print $q->header(-type => 'image/png'); 
binmode(STDOUT);
print $img->png;

exit;



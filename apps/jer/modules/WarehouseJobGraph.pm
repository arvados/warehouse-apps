package WarehouseJobGraph;
use GD;
use WarehouseCache;

my $whc = new WarehouseCache;
$whc->{silent}=1;
$whc->{debug}=0;

# usages:
# $g = new WarehouseJobGraph(image_width=>1024,image_height=>768);
sub new {
	my $class = shift;
	my $self = { @_ };
  bless ($self, $class);
  return $self->_init();
}

sub _init {
	my $self = shift;
	my $border_padding = 3;
	$self->{image_width} ||= 1024;
	$self->{image_height} ||= 768;
	$self->{image_frame_fontsize} ||= 14; #becomes pixel width of frame
 	$self->{vp_x_min} = $self->{image_frame_fontsize}+$border_padding;
	$self->{vp_x_max} = $self->{image_width} - ($self->{image_frame_fontsize}+$border_padding);
	$self->{vp_y_min} = $self->{image_frame_fontsize}+$border_padding;
	$self->{vp_y_max} = $self->{image_height}-(($self->{image_frame_fontsize}+$border_padding)*2);
	$self->{label_fontsize}||=12;
	$self->{label_fontwidth}||=6;
	$self->{label_font}||=gdSmallFont;
	$self->{job_minimum_height}=$self->{label_fontsize}+2;
	$self->{colour_fg} = [192,192,192];
	$self->{colour_bg} = [255,255,255];
	$self->{colour_page} = [64,64,64];
	$self->{colour_borders} = [0,0,0];
	$self->{time_start} ||= undef;  # job_list parameters
	$self->{time_finish} ||= undef;
	$self->{id_start} ||= undef;
	$self->{id_finish} ||= undef;
	$self->{file_name} ||= "temp.png";
	$self->{file_type} ||= "png";
	$self->{errors} = [];
		
	return $self;
}	
	
# _error (string error message) adds an error message to a list of errors to be printed on the image
sub _error {
	my $self = shift;
	push @{$self->{errors}}, $_[0];
	return 1;
}

# _visualize ();
# fills the {rect} and {text} arrays by doing some math
sub _visualize {
	$self = shift;
	return undef unless defined($self->{job_list});
		print "*** joblist OK\n";
	$self->{rect} = []; # left x, top y, right x, bottom y, foreground colour, background colour
	$self->{text} = []; # font, x, y, string, colour 
	#calc the borders
	push @{$self->{rect}}, (0,0,$self->{image_width}-1,$self->{image_height}-1,'border','page'),
		(0,0,$self->{image_width}-1,$self->{image_height}-1,'border','page');
	#calc the bricks
	$self->{time_start} ||= $whc->job_list_statistics('min','starttime');
	$self->{time_finish} ||= $whc->job_list_statistics('max','starttime');
	$self->{nodes_max} ||= $whc->job_list_statistics('max','top');
	#my $xmult = _transformative($self->{time_start},$self->{time_finish},$self->{vp_x_min},$self->{vp_x_max});
	#my $ymult = _transformative(0,$self->{max_nodes},$self->{vp_y_min},$self->{vp_y_max});
	for my $job (values %{$self->{job_list}}) {
		my $x1 = _transform($job->{starttime},$self->{time_start},$self->{time_finish},$self->{vp_x_min},$self->{vp_x_max});
		my $y1 = $self->{image_hight} - _transform($job->{nodes}+$job->{bottom},0,$self->{max_nodes},$self->{vp_y_min},$self->{vp_y_max});
		my $x2 = _transform($job->{finishtime},$self->{time_start},$self->{time_finish},$self->{vp_x_min},$self->{vp_x_max});
		my $y2 = $self->{image_hight} - _transform($job->{bottom},0,$self->{max_nodes},$self->{vp_y_min},$self->{vp_y_max});
		push @{$self->{rect}}, ($x1, $y1, $x2, $y2, 'fg','bg');
		if ($y2-$y1 >= $self->{label_fontsize} && $x2-$x1 > length($job->{mrfunction}) * $self->{label_fontwidth}) {
			push @{$self->{text}}, ( $self->{label_font}, $x1, $y1, $job->{mrfunction}, 'fg'	);
		}
	}
	#TODO other text on image
			
	#draw errors on image
	my $count = (scalar @{$self->{errors}} * $self->{label_font_height} > $self->{image_height} ? int(($self->{image_height} / $self->{label_font_height}) - .5) : scalar @{$self->{errors}} );
	for (my $i=0;$i<=$count;$i++) {
		push @{$self->{text}}, ($self->{label_font}, 2, $i*($self->{label_font_height}+1)+1,pop(@{$self->{errors}}),'fg');
	}			
	return 1;
}

# unit2-index = _transform (unit1-index, unit1-min, unit1-max, unit2-min, unit2-max);
sub _transform {
	my $x = ($_[0] - $_[1]) * ($_[4] - $_[3]) / ($_[2] - $_[1]);
	return ($x>$_[2] ? $_[2] : ($x<$_[1] ? $_[1] : $x)); # bounds checking
}

# unit2-muliplier = _transformative (unit1-min, unit1-max, unit2-min, unit2-max);
sub _transformative {
	return ($_[3]-$_[2]) / ($_[1]-$_[0]);
	# do you own bounds checking
}

# returns the image as PNG data
sub png {
	my $self = shift;
	return $self->_image('png');
}

sub _fetch_jobs {
	my $self = shift;	
	my %components = (id_start=>'id_min', id_finish=>'id_max', time_start=>'finishtime_max', time_finish=>'starttime_min');
	my %params = map { $components{$_} => $self->{$_} } grep { $self->{$_} } keys %components;
	$self->{job_list} = { map{$_->{id}=>$_} @{$whc->job_list( %params )} };
	return undef unless $self->{job_list};
	return 1;
}

# bin $self->_image('png');
# creates the image and returns the raw data
sub _image {
	my $self = shift;
	my $type = shift || $self->{file_type};
	$self->_fetch_jobs();
	$self->_visualize() or return undef;
	print "*** vis ok\n";
	my $im = new GD::Image($self->{image_width}, $self->{image_height});
	my $c = {
		fg=>$im->colorAllocate(@{$self->{colour_fg}}),
		bg=>$im->colorAllocate(@{$self->{colour_bg}}),
		page=>$im->colorAllocate(@{$self->{colour_page}}),
		border=>$im->colorAllocate(@{$self->{colour_borders}})
	};
	print "*** C ok\n";
	for my $r (@$self->{rect}) {
		my $bg = $c->{pop @$r}; #convert box colours to $im's colour registry
		my $fg = $c->{pop @$r};
		if ($bg) { $im->filledRectangle($r, $bg); }
		if ($fg) { $im->rectangle($r, $fg); }
	}
	print "*** R ok\n";
	for my $t (@$self->{text}) {
		push @$t, $c->{pop @$t};
		$im->string($t);
	}		
	if ($type eq "png") {
		return $im->png;
	} elsif ($type eq "gif") {
		return $im->gif;
	} elsif ($type eq "jpg") {
		return $im->jpg;
	}
	return undef;
}

# writes png data to a file, default "temp.png"
sub writefile {
	$self = shift;	
	my $fin = shift || $self->{file_name} || 'temp.png';
	$self->{file_name} =
	$self->{file_type} ||= 'png';
	unless ($fin =~ /^[-_a-zA-Z0-9]{1,128}\.(png|jpg|gif)$/) {
		warn "invalid file name: $fin\n";
		return undef;
	}
	my $im = $self->_image() or die ("Unable to create image (type=".$self->{file_type}.")");
	open(PICTURE, ">$fin") or die("Unable to open image file for writing ($fin)");
	binmode PICTURE;
	print PICTURE $im->png;
	close PICTURE;
	return 1;
}

# _shorthand converts a string like "1024x768 id=10000-12000 time=1182994803-1185318781 file=temp.png" to a hashref suitable for calling ->new
# n-n defaults to time=n-n
sub _shorthand {
	my $in = shift; ## hopefully a string to ensorcel
	my $out = {};
	foreach my $param (split(/\s+/,$in)) {
		if ($param =~ /(\d+)x(\d+)/) {
			$out->{image_width} = int($1);
			$out->{image_height} = int($2);
		} elsif ($param =~ /file=([-_a-zA-Z0-9]+)\.(png|gif|jpg)/) {
			$out->{file_name} = $1.'.'.$2;
			$out->{file_type} ||= $2;
		} elsif ($param =~ /id=(\d+)-(\d+)/) {
			$out->{id_start} = $1;
			$out->{id_finish} = $2;
		} elsif ($param =~ /time=(\d+)-(\d+)/ || $param =~ /(\d+)-(\d+)/) {
			$out->{time_start} = $1;
			$out->{time_finish} = $2;
		} elsif ($param =~ /type=(png|gif|jpg)/) {
			$out->{file_type} = $1;
		}
	}
	return $out;
}

# export functions:

# $data = JobGraph("1024x768 id=10000-12000 time=1182994803-1185318781"
sub main::JobGraph {
	my $g = new WarehouseJobGraph(%{_shorthand(shift @_)});
	return $g->_image();
}

sub main::JobGraphFile {
	my $g = new WarehouseJobGraph(%{_shorthand(shift @_)});
	return $g->writefile();
}
1;

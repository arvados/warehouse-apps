#!/usr/bin/perl

use strict;

use JSON;			# apt-get install libjson-perl
$JSON::UnMapping = 1;

use Getopt::Long;
use Warehouse;			# apt-get install libwarehouse-perl
use Warehouse::Manifest;

$main::Options = {
    "separator" => "\t",
};

GetOptions (
    "separator=s"		=> \$main::Options->{"separator"},
    );

$main::whc = new Warehouse;

my $output_row = 0;
my @argv = @ARGV;
for (@argv) {
    @ARGV = $_;
    my $json;
    do {
	local $/ = undef;
	$json = <>;
    };
    my $pipeline = jsonToObj ($json);
    bless $pipeline, "Warehouse::Pipeline";

    # trimmed read length
    my $readlength = $pipeline->find(name => "bwa-readmap");
    if ($readlength =~ /.{32}/) {
	$readlength = $main::whc->fetch_block_ref ($readlength);
	$readlength = $$readlength;
    }
    $readlength =~ s/[\r\n]*$//;

    # read length distribution (before trimming)
    my @fq_stat_sum = $pipeline->find(name => "fq-stat-sum");
    my @readlengths;
    my @trimmedreadcount;
    push @readlengths, $_->outputdata() foreach @fq_stat_sum;
    for (@readlengths) {
	s/\n$//;
	s/\n/,/g;
	my $qualifiers = "";
	while (/count_(\d+)bp=(\d+)/g) {
	    $qualifiers += $2 if $1 >= $readlength;
	}
	push @trimmedreadcount, $qualifiers;
	s/count_(\d+)bp=(\d+)/$2\@${1}bp/g;
    }

    # sequencing platforms/centers
    my %seq_platform;
    my %seq_center;
    my %seq_desc;
    my $have_paired;
    for my $step ($pipeline->find(name => "sam2fastq")) {
	my $sam = $step->paramvalue ("INPUT");
	if ($sam) {
	    my $wantfile;
	    if ($sam =~ s{(/.*)}{}) {
		$wantfile = "." . $1;
	    }
	    my $m = new Warehouse::Manifest (whc => $main::whc,
					     key => $sam);
	  subdir:
	    while (my $s = $m->subdir_next) {
		while (my ($pos, $size, $filename) = $s->file_next) {
		    last if !defined $pos;
		    next if defined $wantfile && ($s->name . "/" . $filename ne $wantfile);
		    $s->seek ($pos);
		    my $dataref = $s->read_until ($pos + ($size > 1024000 ? 1024000 : $size));
		    if ($dataref) {
			my $top = samtools_view_top ($dataref);
			while ($top =~ m{^(\@RG.*)}gm) {
			    my @rg = split ("\t", $1);
			    for (@rg) {
				$seq_platform{$1}=1 if /^PL:(.+)/;
				$seq_center{$1}=1 if /^CN:(.+)/;
				$seq_desc{$1}=1 if /^DS:(.+)/
			    }
			}
			for (split (/\n/, $top)) {
			    if (m{^[^\@\s]\S+\t(\d+)\t} && ($1 & 1)) {
				$have_paired = "yes";
				last;
			    }
			}
			last subdir;
		    }
		}
	    }
	}
    }

    # aligned reads
    my %aligned;
    my $normal = "normal";
    for my $merge ($pipeline->find(name => "readmap-merge")) {
	my $out = $merge->{"output_data_locator"};
	if ($out) {
	    for ("comb", "comp") {
		chomp ($aligned{"$normal/$_"} = `whget $out/$_.count | head -n1`);
	    }
	}
	$normal = "tumor";
    }

    # ratios
    $aligned{"normal_%repeat"} = sprintf "%.1f", 100 * $aligned{"normal/comb"} / $aligned{"normal/comp"} if $aligned{"normal/comp"} > 0;
    $aligned{"normal_%map"} = sprintf "%.1f", 100 * $aligned{"normal/comp"} / $trimmedreadcount[0] if $trimmedreadcount[0] > 0;
    $aligned{"tumor_%repeat"} = sprintf "%.1f", 100 * $aligned{"tumor/comb"} / $aligned{"tumor/comp"} if $aligned{"tumor/comp"} > 0;
    $aligned{"tumor_%map"} = sprintf "%.1f", 100 * $aligned{"tumor/comp"} / $trimmedreadcount[1] if $trimmedreadcount[1] > 0;

    # timing
    my %elapsed;
    for my $jobname ("sam2fastq", "bwa-readmap") {
	for my $pipestep ($pipeline->find(name => $jobname)) {
	    my $id = $pipestep->{"warehousejob"}->{"id"};
	    my $joblist = $main::whc->job_list(id_min => $id, id_max => $id);
	    for my $job (@$joblist) {
		if ($job->{"thawedfromkey"} || !$job->{"starttime_s"} || !$job->{"finishtime_s"}) {
		    $elapsed{$jobname} = -1;
		} elsif (!($elapsed{$jobname} < 0)) {
		    $elapsed{$jobname} += $job->{"finishtime_s"} - $job->{"starttime_s"};
		}
		last;
	    }
	}
	if ($elapsed{$jobname} <= 0) {
	    $elapsed{$jobname} = "";
	} else {
	    $elapsed{$jobname} = sprintf "%.3f", $elapsed{$jobname} / 86400;
	}
    }

    my $bwa_aln_flags;
    my @readmap = $pipeline->find(name => "bwa-readmap");
    for (@readmap) {
	if (my $metadata = $_->metadata) {
	    my $jobstepid;
	    if ($metadata =~ m{^\S+ \d+ \d+ \d+ stderr .*?bwa aln (.*?) /}m) {
		$bwa_aln_flags = $1;
	    }
	}
    }

    my $output = $pipeline->find(name => "readmap-ratio")->{"output_data_locator"};

    print (join ($main::Options->{"separator"},
		 qw(label platform center rg_desc paired normal_inputs tumor_inputs trim_length normal_trimmed_count tumor_trimmed_count bwa_aln_flags normal_comb_count normal_comp_count normal_%repeat normal_%map tumor_comb_count tumor_comp_count tumor_%repeat tumor_%map output fastq_days readmap_days)),
	   "\n")
	if ++$output_row == 1;

    print (join ($main::Options->{"separator"},
		 $pipeline->{label},
		 join (",", sort keys %seq_platform),
		 join (",", sort keys %seq_center),
		 join (",", sort keys %seq_desc),
		 $have_paired,
		 @readlengths,
		 $readlength,
		 @trimmedreadcount,
		 $bwa_aln_flags,
		 $aligned{"normal/comb"},
		 $aligned{"normal/comp"},
		 $aligned{"normal_%repeat"},
		 $aligned{"normal_%map"},
		 $aligned{"tumor/comb"},
		 $aligned{"tumor/comp"},
		 $aligned{"tumor_%repeat"},
		 $aligned{"tumor_%map"},
		 $output,
		 $elapsed{"sam2fastq"},
		 $elapsed{"bwa-readmap"},
	   ),
	   "\n");
}

sub samtools_view_top
{
    my $dataref = shift;
    pipe R, W or die "no pipe";
    my $child = fork;
    die "no fork" if !defined $child;
    if ($child) {
	close W;
	my $ret;
	local $/ = undef;
	while (<R>) {
	    $ret .= $_;
	}
	close R;
	wait;
	die "samtools child exited $?" if ($? >> 8 != 0);
	return $ret;
    }
    close R;
    open STDOUT, ">&W" or die "no dup";
    open STDERR, ">/dev/null";
    open X, "|-", "samtools", "view", "-h", "-";
    print X $$dataref;
    close X;
    exit;
}

package Warehouse::Pipeline;

sub find
{
    my $self = shift;
    my %query = @_;
    my @ret;
    foreach (@{$self->{steps}}) {
	if (exists $query{"name"} && $_->{"name"} eq $query{"name"}) {
	    bless $_, "Warehouse::Pipeline::Step";
	    push @ret, $_;
	}
    }
    return @ret if wantarray;
    if (@ret != 1) {
	die "Expected 1, found ".(scalar @ret)." matching step for ".$query{"name"};
    }
    return $ret[0];
}

package Warehouse::Pipeline::Step;

sub metadata
{
    my $self = shift;
    my $out = $self->{"warehousejob"}->{"metakey"};
    return undef if !$out;
    $out = $main::whc->fetch_block_ref ($out);
    return $$out;
}

sub outputdata
{
    my $self = shift;
    my $out = $self->{"output_data_locator"};
    return undef if !$out;
    my $manifest = new Warehouse::Manifest ("key" => $out, "whc" => $main::whc);
    my $ret;
    while (my $s = $manifest->subdir_next) {
	while (my ($pos, $size, $filename) = $s->file_next) {
	    last if !defined $pos;
	    $s->seek ($pos);
	    while (my $dataref = $s->read_until ($size)) {
		$ret = "" if !defined $ret;
		$ret .= $$dataref;
	    }
	}
    }
    return $ret;
}

sub paramvalue
{
    my $self = shift;
    my $paramname = shift;
    foreach my $param (@{$self->{"params"}}) {
	if ($param->{"name"} eq $paramname) {
	    foreach (qw(value data_locator)) {
		return $param->{$_} if exists $param->{$_};
	    }
	    return undef;
	}
    }
    return undef;
}

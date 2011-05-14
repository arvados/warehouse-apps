#!/usr/bin/perl

if (@ARGV < 3 || @ARGV > 4)
{
    die <<EOF;
usage: $0 m n filtertype [reduce-cat-outputkey]
 filtertype = all | genomic | genomic-100bp-runs
EOF
;
}

my $wantm = shift @ARGV;
my $wantn = shift @ARGV;
my $filtertype = shift @ARGV;
my $filter_genomic = $filtertype =~ /genomic/;
my $filter_100bp = $filtertype =~ /100bp/;

if (@ARGV == 1 && $ARGV[0] =~ /^[\da-f]{32}$/)
{
    open STDIN, "whget $ARGV[0]/megatri-count.txt - |" or die $!;
    shift @ARGV;
}

my $center_xy = {};
my %center;
my $N;
while (<>)
{
    if (/^\#example: m=$wantm n=$wantn (..).*;center_name:\s*(.*?);.*;source_type:\s*(.*?);.*/)
    {
	my $xy = $1;
	my $center = $2;
	$center{$center} ||= 0;
	next if ($filter_genomic && $3 ne "GENOMIC");
	next if ($filter_100bp && !/\}\S+ \d+ \d\d\d/);
	next if $xy =~ /n$/;
	$center_xy->{$center} ||= {};
	$center_xy->{$center}->{$xy} ++;
	$center{$center} ++;
	$N ++;
    }
}

my @center = sort keys %center;
for my $center (@center)
{
    print "\t$center";
}
print "\n";

for my $xy (qw(ac ag at ca cg ct ga gc gt ta tc tg))
{
    print "$xy";
    for my $center (@center)
    {
	my $count = 0 + $center_xy->{$center}->{$xy};
	print "\t$count";
    }
    print "\n";
}

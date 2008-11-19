package MAQ::mapsort;

use strict;
use warnings;

use MAQ::map;
use IO::Compress::Gzip qw($GzipError);

# This only works within a single chromosome, since it does not sort by chromosome number
sub new {
  my $class = shift;
  my $self = { _recs => [], _counts => [map { 0 } 0 .. 1_000_000] };
  bless $self, $class;
}

sub insert {
  my $self = shift;
  my %rec = @_;
  return if (++$self->{_counts}[$rec{pos}>>1] > 5);
  push @{$self->{_recs}}, [ $rec{pos}, MAQ::map::pack_rec(%rec) ];
}

sub emit {
  my $self = shift;
  my $out = shift;
  my $zout = new IO::Compress::Gzip $out
    or die "gzip failed: $GzipError\n";
  my @recs = sort { $a->[0] <=> $b->[0] } @{$self->{_recs}};
  foreach my $rec (@recs) {
    $zout->write($rec->[1]);
  }
  return $zout->close;
}

1;


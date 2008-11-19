package MAQ::map;

use strict;
use warnings;

use IO::Compress::Gzip qw($GzipError);
use IO::Uncompress::Gunzip qw($GunzipError);

my $RECLEN = 64+8+4+4+4+36;

sub new {
  my $class = shift;
  my $file = shift;
  my $mode = shift || 'r';
  my $skip_header = shift || 0;

  my $self = { _header => $skip_header ? 1 : 0, _nrec => $skip_header ? 'any' : 0, _format => -1 };
  bless $self, $class;

  if ($mode eq 'r') {
    my $in = $self->{_in} = new IO::Uncompress::Gunzip $file
      or die "gunzip failed: $GunzipError\n";
    unless ($skip_header) {
      my $buffer;
      $in->read($buffer, 8);
      my ($format, $n_ref) = unpack "ll", $buffer;
      print "format $format\n";
      die unless $self->{_format} == $format;
      my @refs;
      for (my $ind = 0 ; $ind < $n_ref ; $ind++) {
        $in->read($buffer, 4);
        my ($len) = unpack "l", $buffer;
        die unless $len < 1000;
        $in->read($buffer, $len);
        chop $buffer;
        push @refs, $buffer;
      }
      $self->{_refs} = \@refs;
      $in->read($buffer, 8);
      ($self->{_nrec}) = unpack "Q", $buffer;
      $self->{_header} = 1;
    }
  }
  elsif ($mode eq 'w') {
    $self->{_out} = new IO::Compress::Gzip $file
      or die "gzip failed: $GzipError\n";
  }
  else {
    die "unknown mode $mode";
  }
  $self;
}

sub read {
  my $self = shift;
  die unless $self->{_in};

  if ($self->{_nrec} ne 'any') {
    return () if $self->{_nrec} == 0;
    $self->{_nrec}--;
  }

  my $buffer;
  my $nread = $self->{_in}->read($buffer, $RECLEN);
  if ($nread <= 0) {
    return () if ($self->{_nrec} eq 'any');
    die "could not read all of the records, $self->{_nrec} left";
  }

  my %r;
  ($r{seq}, $r{size}, $r{map_qual}, $r{info1}, $r{info2}, $r{c1}, $r{c2}, $r{flag}, $r{alt_qual}, $r{seqid}, $r{pos}, $r{dist}, $r{name}) =
    unpack("a64aaaaaaaalllZ36", $buffer);
  $r{chr} = $self->{_refs}[$r{seqid}];
  %r;
}

sub write_header {
  my $self = shift;
  my $nrec = shift;
  my @refs = @_;
  die unless $self->{_out};
  die if $self->{_header};
  die unless ($nrec >= 0 && scalar(@refs) > 0);

  my $buffer;
  $buffer = pack "ll", $self->{_format}, scalar(@refs);
  $self->{_out}->write($buffer);
  foreach my $ref (@refs) {
    $buffer = pack("l", length($ref)+1);
    $self->{_out}->write($buffer);
    $self->{_out}->write($ref . "\0");
  }
  $buffer = pack "Q", $nrec;
  $self->{_out}->write($buffer);
  $self->{_nrec} = $nrec;
  $self->{_header} = 1;
}

sub write {
  my $self = shift;
  my %r = @_;
  die "not in write mode" unless $self->{_out};
  die "header not written" unless $self->{_header};

  if ($self->{_nrec} ne 'any') {
    die if $self->{_nrec} <= 0;
    $self->{_nrec}--;
  }

  $self->{_out}->write(pack_rec(%r));
}

sub pack_rec {
  my %r = @_;
  my $buffer = pack "a64aaaaaaaalllZ36",
    ($r{seq}, $r{size}, $r{map_qual}, $r{info1}, $r{info2}, $r{c1}, $r{c2}, $r{flag}, $r{alt_qual}, $r{seqid}, $r{pos}, $r{dist}, $r{name});
}

sub close {
  my $self = shift;
  die "did not read/write all recs - $self->{_nrec} left" if $self->{_nrec} && $self->{_nrec} ne 'any';
  if ($self->{_in}) {
    return $self->{_in}->close;
  }
  else {
    return $self->{_out}->close;
  }
}

1;

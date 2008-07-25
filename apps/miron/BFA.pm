package BFA;

use strict;
use warnings;
use Fcntl qw(SEEK_CUR);
use IO::File;


sub new {
  my ($class, $file, %self) = @_;
  bless \%self, $class;
  $self{fh} = new IO::File $file or die "open";
  for (my $chr = 0 ; $chr <= 255 ; $chr++) {
    my $value = $chr;
    my $res = "";
    for (my $ind = 0 ; $ind < 4 ; $ind++) {
      $res .= substr("ACGT", $value & 3, 1);
      $value >>= 2;
    }
    $self{decode}[$chr] = scalar reverse $res;
  }
  \%self;
}

sub find {
  my $self = shift;
  my $my_name = shift;

  my $buf;

  my $fh = $self->{fh};

  $fh->seek(0, SEEK_SET);
  while (!eof $fh) {
    read $fh, $buf, 4;
    my ($name_len) = unpack "i", $buf;
    die "name len $name_len" if ($name_len > 100 || $name_len <= 0);
    my $name;
    read $fh, $name, $name_len;
    read $fh, $buf, 4;
    read $fh, $buf, 4;
    my ($data_len) = unpack "i", $buf;
    chop $name;
    #warn "$name len=$data_len\n";
    if ($name ne $my_name) {
      seek $fh, $data_len * 8 * 2, SEEK_CUR;
    }
    else {
      my $data;
      read $fh, $data, $data_len * 8;
      $self->{data} = $data;
      return 1;
    }
  }
  warn "not found $my_name";
  return undef;
}

sub get {
  my $self = shift;
  my $offset = shift;

  my $start = int($offset / 32) * 8;
  # get 96 bp
  my $res = $self->get64($start) . $self->get64($start+8) . $self->get64($start+16);
  $res = substr($res, $offset - $start * 4);
  return $res;
}

sub get64 {
  my $self = shift;
  my $offset = shift;

  my $res = "";
  for (my $chr = 7 ; $chr >= 0 ; $chr--) {
    my $value = ord(substr($self->{data}, $offset + $chr, 1));
    $res .= $self->{decode}[$value];
  }
  return $res;
}

sub walk {
  my $self = shift;
  my $offset = shift;

  my $cur_offset = $self->{walk_offset};
  $self->{walk_offset} = $offset;

  my $data = $self->{walk_data};
  return $data if (defined $cur_offset && $cur_offset == $offset);
  if (defined $cur_offset &&
      $offset > $cur_offset &&
      $offset - $cur_offset <= length($data) - 48) {
    $data = substr($data, $offset - $cur_offset);
    $self->{walk_data} = $data;
    return $data;
  }

  $self->{walk_data} = $self->get($offset);
  return $self->{walk_data};
}

1;

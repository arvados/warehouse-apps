#!/usr/bin/perl

use strict;
use warnings;

use Net::FTP;
use URI::URL;
use Warehouse;

# usage: ./ftp-store.pl ftp://ftp.ncbi.nih.gov/pub/TraceDB/ShortRead/SRA000271/fastq SRA000271

my $READSIZE = 32*1024*1024;
my $url = shift;
$url = new URI::URL $url;

my $subdir = shift;

my $cmd = 'zcat | /home/miron/maq-0.6.6/maq fastq2bfq - %s';
my $suffix = 'bfq';

my $basedir = "/tmp/store-$subdir";
my $metadir = $ENV{HOME} . "/.ftpstore-meta";
mkdir $metadir;
mkdir "$metadir/$subdir";
mkdir $basedir;
mkdir "$basedir/$subdir";

my $whc = new Warehouse ();

my $ftp = new Net::FTP($url->host, Debug => 0)
  or die "cannot connect";
$ftp->login("anonymous", 'miron@hyper.to')
  or die $ftp->message;
$ftp->cwd($url->path)
  or die $ftp->message;
$ftp->binary;
my @files = sort $ftp->ls;
my $count = 0;
foreach my $file (@files) {
  $count++;
  my $outname = $file;
  $outname =~ s/\..*/.$suffix/;

  next if -f "$metadir/$subdir/$outname";
  print STDERR "$count of ", scalar(@files), ": $outname\n";
  my $conn = $ftp->retr($file);
  my $size = 0;
  my $buf;
  
  open OUT, sprintf("|$cmd", "$basedir/$subdir/$outname");
  while (my $nread = $conn->read($buf, $READSIZE)) {
    die if !defined $nread;
    $size += $nread;
    print OUT $buf;
  }
  $conn->close;
  close OUT;

  $whc->write_start;
  my $bfq_size = send_file($whc, "$basedir/$subdir/$outname");
  my @stream_hashes = $whc->write_finish;
  open OUT, ">$metadir/$subdir/$outname";
  print OUT "./$subdir @stream_hashes 0:$bfq_size:$outname\n";
  close OUT;
  unlink "$basedir/$subdir/$outname";
}

sub send_file
{
    my $whc = shift;
    my $file = shift;
    open FILE, "<$file" or die "Can't open $file: $!";
    my $buf;
    my $bytes;
    my $totalsize = 0;
    while ($bytes = read FILE, $buf, 1048576) {
	$whc->write_data ($buf) or die "Warehouse::write_data failed";
	$totalsize += $bytes;
    }
    if (!defined $bytes)
    {
	die "Read error: $file: $!";
    }
    close FILE or die "Read error: $file: $!";
    return $totalsize;
}


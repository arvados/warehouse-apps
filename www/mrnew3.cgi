#!/usr/bin/perl

use strict;
use CGI ':standard';

do '/etc/polony-tools/config.pl';

my $q = new CGI;
print $q->header;

my $rev = $q->param('revision') + 0;

my $defaultknobs = '';
my $inputtype = 'images';
if (open F,
    "svn cat '$main::svn_repos/mapreduce/mr-"
    .$q->param('mrfunction')
    ."\@$rev' |")
{
  foreach (<F>)
  {
    if (/^\#\#\#MR_INPUT:(\S+)/)
    {
      $inputtype = $1;
    }
    elsif (/^\#\#\#MR_KNOBS:(\S+)/)
    {
      $defaultknobs .= "$1\n";
    }
  }
  close F;
}

if ($inputtype eq 'images' ||
    $inputtype eq 'frames')
{
  eval `cat mrnew3-$inputtype.cgi` or die "$!";
}

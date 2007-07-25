#!/usr/bin/perl

use strict;
use CGI ':standard';

do '/etc/polony-tools/config.pl';

my $q = new CGI;
print $q->header;

my $inputtype = 'images';
if (open F, "<../mapreduce/mr-".$q->param('mrfunction'))
{
  foreach (<F>)
  {
    if (/^\#\#\#MR_INPUT:(\S+)/)
    {
      $inputtype = $1;
    }
  }
  close F;
}

if ($inputtype eq 'images' ||
    $inputtype eq 'frames')
{
  eval `cat mrnew3-$inputtype.cgi` or die "$!";
}

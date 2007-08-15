#!/usr/bin/perl

use strict;
use CGI ':standard';
do 'mrlib.pl';

do '/etc/polony-tools/config.pl';

my $q = new CGI;
print $q->header;

my $rev = $q->param('revision') + 0;

my %mrparam = mr_get_mrfunction_params ($q->param('mrfunction'), $rev);
my $defaultknobs = $mrparam{"MR_KNOBS"};
my $inputtype = $mrparam{"MR_INPUT"};

if ($inputtype eq 'images' ||
    $inputtype eq 'frames')
{
  eval `cat mrnew3-$inputtype.cgi` or die "$!";
}

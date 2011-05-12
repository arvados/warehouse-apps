#!/usr/bin/perl

use strict;
use CGI;

my $q = new CGI;
print $q->header (-type=>"text/plain");
print `mogadm check 2>&1`;

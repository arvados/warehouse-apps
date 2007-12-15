#!/usr/bin/perl

use strict;

if ($ENV{PATH_INFO} =~ /^\/job\d|^\/[0-9a-f]{32}(\/|$)/)
{
    exec "whget.cgi";
}

eval
{
  use CGI;
  my $q = new CGI;
  print $q->header (-status=>404,
		    -type=>"text/plain");
  print "404 Not found\n";
}

#!/usr/bin/perl

use strict;

my $md5re = "[0-9a-f]{32}";
my $hintre = "\+[\d\w\@]+";
my $hashre = "$md5re(?:$hintre)*";
my $keyre = "$hashre(?:,$hashre)*";

if ($ENV{PATH_INFO} =~ /^\/job\d|^\/$keyre(\/|\.txt$|$)/)
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

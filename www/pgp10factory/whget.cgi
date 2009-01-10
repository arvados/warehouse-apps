#!/usr/bin/perl

use strict;

my $md5re = q{[0-9a-f]{32}};
my $hintre = q{\+[\d\w\@]+};
my $hashre = qq{$md5re(?:$hintre)*};
my $keyre = qq{$hashre(?:,$hashre)*};

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

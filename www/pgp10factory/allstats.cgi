#!/usr/bin/perl

use strict;
use CGI;

print "Content-type: text/plain\n\n";

if ($ENV{QUERY_STRING} =~ /([0-9a-f]{32})/)
{
    exec "/usr/local/polony-tools/current/apps/tomc/pgp10stats cache $1";
}

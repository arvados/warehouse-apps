#!/usr/bin/perl

## Example usage:
# Alias /tar /tmp/download-tar.cgi
# <Location /tar>
#  SetHandler cgi-script
#  Options -MultiViews +ExecCGI
# </Location>
## --> http://vhost/tar/2622f6fe48669f66a0c5cc7650a3458a+162960+K@ant.tar

use strict;
use Warehouse;
use CGI ':standard';

my $q = new CGI;

my $collection;
if ($q->param('collection')) {
    $collection = $q->param('collection');
}
elsif ($ENV{PATH_INFO} =~ m{([0-9a-f]{32}[^/]*)}) {
    $collection = $1;
}
$collection =~ s{ }{+}g;
$collection =~ s{[^\+\w\@,]}{}g;

my $content_length = `whtar --output-length-only --create $collection`;
chomp $content_length;

print $q->header (-type => 'application/x-tar',
                  -attachment => '$collection.tar',
                  -content_length => $content_length,
    );

my $prefix = $collection;
$prefix =~ s{\+[^,]*}{}g;
exec("whtar --create --prefix \"$prefix\" \"$collection\"");

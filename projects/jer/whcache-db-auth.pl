#!/usr/bin/perl

sub main::dsn_vars {
    if (-f "$ENV{HOME}/.whcache.conf")
    {
	do "$ENV{HOME}/.whcache.conf";
    }
    (
# data source name
$ENV{'DB_DSN'},			# eg. "DBI:mysql:whcache:localhost:3306"

# data source username
$ENV{'DB_USER'},		# eg. "www1"

# data source password
$ENV{'DB_PASS'},		# eg. "blurfl"
) }
1;

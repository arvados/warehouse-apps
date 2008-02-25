#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME => 'Warehouse',
     VERSION_FROM => 'lib/Warehouse.pm',
     EXE_FILES => [
		   'client/whcopy',
		   'client/whence',
		   'client/whget',
		   'client/whput',
		   'client/whget.cgi',
		   'server/memcached-install.sh',
		   'server/memcached-show-servers.pl',
		   'server/mogilefs-install.sh',
		   'server/mogilefs-check.pl',
		   'server/mogilefs-create-devices.pl',
		   'server/warehoused',
		   'server/keepd',
		   ]
     );

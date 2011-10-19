#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME => 'Warehouse',
     VERSION_FROM => 'lib/Warehouse.pm',
     EXE_FILES => [
		   'client/auto_rebalance_keep.pl',
		   'client/wh',
		   'client/whcheck',
		   'client/whcopy',
		   'client/whence',
		   'client/whget',
		   'client/whget.cgi',
		   'client/whintro',
		   'client/whjob-checkout-and-build',
		   'client/whless',
		   'client/whmount',
		   'client/whpipeline',
		   'client/whput',
		   'client/rwhence',
		   'server/memcached-install.sh',
		   'server/memcached-show-servers.pl',
		   'server/mogilefs-install.sh',
		   'server/mogilefs-check.pl',
		   'server/mogilefs-create-devices.pl',
		   'server/warehouse-watchdog',
		   'server/warehoused',
		   'server/warehoused-initialize-tables.pl',
		   'server/whjobinit',
		   'server/whjobmanager',
		   'server/keepd',
		   ]
     );

#!/usr/bin/perl
use strict;

use lib "/usr/local/polony-tools/current/apps/jer/modules";
use WarehouseCache;

$|=1;

my $whc = new WarehouseCache;

# stdout control
$whc->{silent} = 0;
$whc->{debug} = 1;

# update the database & caculates the new nodes
$whc->update();


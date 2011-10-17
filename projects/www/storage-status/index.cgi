#!/usr/bin/perl

use strict;
use Warehouse;
use CGI ':standard';
use JSON;

my $q = new CGI;
my $whc = new Warehouse;

print $q->header ('text/html');
print qq{
<html>
<head>
 <title>$whc->{config}->{name} storage status</title>
<style type="text/css">
};
print stylesheet();
print qq{
</style>
</head>
<body>
};

print "<table><thead>\n";
print "<tr><td>node</td><td>a</td><td>b</td><td>c</td><td>d</td><td>e</td><td>f</td><td>g</td><td>h</td><td class=\"right\">used</td><td>avail</td><td></td></tr>\n";
print "</thead><tbody>\n";

my $cluster_size = 0;
my $cluster_avail = 0;
my $cluster_used = 0;
my ($keeps, @bucket) = $whc->_hash_keeps (undef, "00000000000000000000000000000000");
for (@$keeps) {
    my $host = $_;

    $host =~ /^(.[^\.]*)/;
    print "<tr><td>$1</td>\n";

    my $status;
    if ($whc->{config}->{keeps_status}->{$host} =~ /^down/) {
	print "<td colspan=\"8\" class=\"down\">down</td></tr>\n";
	next;
    }
    eval {
	$status = JSON::from_json(`curl -s http://$host/status.json`);
    };
    if (!$status) {
	print "<td colspan=\"8\" class=\"unknown\">unknown</td></tr>\n";
	next;
    }

    my $node_size = 0;
    my $node_avail = 0;
    my $node_used = 0;
    for my $slot (qw(a b c d e f g h)) {
	my @slot_dev;
	my $slot_size = '-';
	my $slot_used = '-';
	my $slot_avail = '-';
	my $slot_error;
	my $slot_has_keep;
	my $slot_has_mounts;
	for my $dev (@{$status->{'disk_devices'}}) {
	    if ($dev =~ /^.*d${slot}\d*/) {
		push @slot_dev, $dev;
	    }
	}
	for (split (/\n/, $status->{'df'})) {
	    my ($dev, $size, $used, $avail, $usepct, $mount) = split;
	    if ($dev =~ /^\/dev\/\S+d${slot}\d*/) {
		$slot_has_mounts = 1;
		for my $dir (keys %{$status->{'dirs'}}) {
		    if ($dir =~ /^\Q$mount\E(\/|$)/) {
			$slot_size += $size;
			$slot_used += $used;
			$slot_avail += $avail;
			$slot_has_keep = 1;
			last;
		    }
		}
	    }
	}
	if ($slot_has_keep) {
	    printf "<td class=\"right ok\">%d</td>", $slot_avail/1024/1024;
	} elsif ($slot_has_mounts) {
	    printf "<td class=\"right nokeep\">nokeep</td>";
	} elsif (@slot_dev) {
	    printf "<td class=\"right nomount\">nomount</td>";
	} else {
	    printf "<td class=\"right empty\">-</td>";
	}
	$cluster_size += $slot_size;
	$cluster_avail += $slot_avail;
	$cluster_used += $slot_used;
	$node_size += $slot_size;
	$node_avail += $slot_avail;
	$node_used += $slot_used;
    }
    my $used_px = $node_used / 1024 / 1024 / 20;
    my $avail_px = $node_avail / 1024 / 1024 / 20;
    print "<td class=\"right\"><div class=\"bargraph used\" style=\"width:${used_px}px\"></div></td><td><div class=\"bargraph avail\" style=\"width:${avail_px}px\"></div></td>\n";
    my $lost = ($node_size - $node_avail - $node_used)/1024/1024;
    $lost = $lost < 1 ? "" : sprintf ", %d GiB lost/reserved", $lost;
    printf "<td>%.1f TiB used, %.1f TiB avail%s</td>\n", $node_used/1024/1024/1024, $node_avail/1024/1024/1024, $lost;
    print "</tr>\n";
}
my $cluster_size_tb = sprintf ("%.1f", $cluster_size / 1024 / 1024 / 1024);
my $cluster_used_percent = sprintf ("%.1f", 100 * $cluster_used / $cluster_size);
my $cluster_avail_percent = sprintf ("%.1f", 100 * $cluster_avail / $cluster_size);
print qq{
</tbody></table>
<table><tbody>
 <tr><td>total size</td><td class="right">$cluster_size KiB&nbsp;</td><td class="right">$cluster_size_tb</td><td>TiB</td></tr>
 <tr><td>total used</td><td class="right">$cluster_used KiB&nbsp;</td><td class="right">$cluster_used_percent</td><td>%</td></tr>
 <tr><td>total avail</td><td class="right">$cluster_avail KiB&nbsp;</td><td class="right">$cluster_avail_percent</td><td>%</td></tr>
</tbody></table>
</body>
</html>
};

sub stylesheet
{
    q{
.right {
  text-align: right;
}
.down {
  background: #ffcccc;
}
.unknown {
  background: #cccccc;
}
.ok {
  background: #ccffcc;
}
.nokeep {
  background: #ffffff;
}
.nomount {
  background: #ffffcc;
}
.empty {
  background: #ffffff;
}
.bargraph {
  height: 1em;
  display: inline-block;
}
.bargraph.used {
  background: #aaaaff;
}
.bargraph.avail {
  background: #aaffaa;
}
};
}

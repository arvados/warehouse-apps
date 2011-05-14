#!/usr/bin/perl

use strict;

my $hostname = `hostname -s`;
chop $hostname;

my $hostnumber = $hostname;
$hostnumber =~ s/^.*?(\d+)\D*$/$1/g;
$hostnumber = sprintf "%02d", $hostnumber;

opendir DEV, "/dev" or die "/dev: $!";
my @blockdev = sort grep { /^[hs]d/ } readdir DEV;
closedir DEV;

my %local_devno_partition;
my %mount;
grep {
    if (m,^/dev/([sh]d.\d) on (\S+),)
    {
	$mount{$1} = $2;
	my @stat = stat $2;
	$local_devno_partition{$stat[0]} = $1;
    }
} `mount`;

my %disk;
my %disk_has_partitions;
my %partition_disk;
foreach (@blockdev)
{
    if (/\d+$/)
    {
	$partition_disk{$_} = $`;
	$disk_has_partitions{$`} ++;
	if (!exists $disk{$`})
	{
	    # this is a xen domU and we don't have the whole disk, only part(s)
	}
    }
    else
    {
	$disk{$_} = $_;
    }
}

my $hwtype;
foreach (`lshw`)
{
    if (/^\s*\*-(\S+)/) { $hwtype = $1; }
    if ($hwtype eq 'cdrom')
    {
	if (m,^\s*logical name: /dev/([sh]d[a-z])$,) { delete $disk{$1} }
    }
}

foreach (sort keys %disk)
{
    if (!exists $disk_has_partitions{$_})
    {
	warn "$_ on $hostname has no partitions\n";
    }
}

my %disk_slot;

my @scsiadd = `/usr/sbin/scsiadd -p 2>/dev/null`;
if (!@scsiadd)
{
    $disk_slot{"hda"} = 1;
    $disk_slot{"hdb"} = 2;
    $disk_slot{"hdc"} = 3;
    $disk_slot{"hdd"} = 4;
    $disk_slot{"sda"} = 1;
    $disk_slot{"sdb"} = 2;
    $disk_slot{"sdc"} = 3;
    $disk_slot{"sdd"} = 4;
}

my @slot_has_disk;
my $abcd = 'a';
foreach (@scsiadd)
{
    if (/^Host: scsi(\d)/)
    {
	$slot_has_disk[$1 + 1] = "sd$abcd";
	$disk_slot{"sd$abcd"} = $1 + 1;
	$abcd = chr(ord($abcd) + 1);
    }
}

my $sys_block = '/sys/block/';

opendir(DIR, $sys_block) || die "can’t opendir $sys_block: $!";
my @bdevs = grep { /^(s|h)d./ && -d "$sys_block/$_" } readdir(DIR);
closedir DIR;

for (@bdevs) {
	my $device = $_;

	# get bayno
	my $bayletter = $device;
	$bayletter =~ s/^..(.).*/$1/;
	$disk_slot{$device} = 1 + ord($bayletter) - ord('a');
	$slot_has_disk[1 + ord($bayletter) - ord('a')] = $device;
}

if (!@slot_has_disk)
{
    foreach my $xd ("hd", "sd")
    {
	foreach my $abcd (qw(a b c d))
	{
	    $slot_has_disk[ord($abcd) - 'a' + 1] = "$xd$abcd"
		if exists $disk{"$xd$abcd"};
	}
    }
}

-e "/etc/mogilefs/mogstored.conf" or die "$hostname: no /etc/mogilefs/mogstored.conf\n";

my $mogilefs_docroot;
foreach (`cat /etc/mogilefs/mogstored.conf 2>/dev/null`)
{
    if (/^\s*docroot\s*=\s*(\S+)/)
    {
	$mogilefs_docroot = $1;
    }
}

my @slot_has_mogilefs;
opendir MR, $mogilefs_docroot or die "$hostname: $mogilefs_docroot: $!";
foreach (readdir MR)
{
    if (/^dev(\d+)$/)
    {
	my $mogilefs_devno = $1;
	my @stat = stat "$mogilefs_docroot/$_/.";
	my $part = $local_devno_partition{$stat[0]};
	my $slot = $disk_slot{$partition_disk{$part}};
	$slot_has_mogilefs[$slot] = 1;
	$mogilefs_devno =~ /^(\d)?(\d)?(\d\d)?/;
	if ($2 ne $slot
	    ||
	    $3 ne $hostnumber)
	{
	    warn "dev$mogilefs_devno on $hostname should be dev*$slot$hostnumber\n";
	}
    }
}
closedir MR;

my $slot_graph = "";
for (1..4)
{
    if (!$slot_has_disk[$_])
    {
	$slot_graph .= "_ ";
    }
    elsif ($slot_has_mogilefs[$_])
    {
	$slot_graph .= "+ ";
    }
    else
    {
	$slot_graph .= "! ";
	warn "$slot_has_disk[$_] on $hostname has no mogilefs device\n";
    }
}
print "$slot_graph $hostname\n";

#!/usr/bin/perl
use strict;

# mogilefs-create-devices2.pl
# Heavily modified from Tom's orginal version.
# Ward, 2007-12-06

select STDERR; $|=1;
select STDOUT; $|=1;

my %dev;
my $DEBUG = 0;

my $sfdisk_command = "sfdisk";
if ($ENV{SFDISK_NO_REREAD})
{
    $sfdisk_command = "sfdisk --no-reread";
}

my $hostname = `hostname -s`;
chomp $hostname;
my $nodeno = $hostname;
$nodeno =~ s/\D//g;
$nodeno = sprintf "%02d", $nodeno;

sub add_to_mogilefs() {
	my ($hostname, $device, $mogroot, $nodeno) = (shift,shift,shift,shift);
	my %dev = @_;
  warn "# $hostname -- mount-and-add $device " . sprintf("%.2f",$dev{$device}{size}/1024/1024/1024) . "GB\n";
  my $devno = "1$dev{$device}{bayno}$nodeno";
  print "mkdir -p $mogroot/$device || (rmdir $mogroot/$device && mkdir $mogroot/$device)\n";
  print "ln -sf $device/dev$devno $mogroot/dev$devno\n";
  print "perl -pi~ -e 's,^/dev/$device ,#\$&,' /etc/fstab\n";
  print "echo >>/etc/fstab /dev/$device $mogroot/$device ext3 defaults 1 2\n";
  print "if mount /dev/$device; then\n";
  print "  mkdir -p $mogroot/$device/do_not_delete\n";
  print "  mv -i $mogroot/$device/* $mogroot/$device/do_not_delete/ || true\n";
  print "  mkdir $mogroot/$device/dev$devno\n";
  print "fi\n";
  warn "# $hostname -- mogadm-device-add $_\n";
  print "mogadm device add $hostname $devno --status=alive\n";
}

my %devfile_devno;		# device special file -> local device number
my %devfile_mount;		# device special file -> mount point
foreach (`mount`)
{
    chop;
    my @m = split;
		my $tmp = $m[0];
		$tmp =~ s,^/dev/,,;
		$dev{$tmp}{mountpoint} = $m[2];

    $devfile_mount{$m[0]} = $m[2];
    my @stat = stat "$m[2]/.";
    $devfile_devno{$m[0]} = $stat[0];
}

my %mogdev_exists;		# devXXXX -> 1
my %devno_mogdev;		# local device number -> devXXXX
my %mogdev_devno;		# devXXXX -> local device number
my ($mogroot) = grep { $_ } map { $1 if /^\s*docroot\s*=\s*(\S*).*/; }
    `grep docroot /etc/mogilefs/mogstored.conf`;
opendir M, $mogroot or die "$hostname: opendir $mogroot: $!";
foreach (readdir M)
{
    if (/^dev\d+$/)
    {
	my @stat = stat "$mogroot/$_/.";
	$mogdev_exists{$_} = 1;
	$mogdev_devno{$_} = $stat[0];
	$devno_mogdev{$stat[0]} = $_;
    }
}
closedir M;

my %disksize;
my %disk_partitions;
my %disk_has_mogilefs;

# If we have lvm tools installed, let's check if we have any physical lvm volumes
my @tmp = split("\n",`pvdisplay 2>/dev/null`);
foreach (@tmp) {
	if (m,^/dev/(.*?)\s,) {
		$dev{$1}{signature} = "lvm";
	}
}

# Get swap devices
@tmp = split("\n",`swapon -s`);
foreach (@tmp) {
	if (m,^/dev/(.*?)\s,) {
		$dev{$1}{signature} = "swap";
	}
}

my $sys_block = '/sys/block/';

opendir(DIR, $sys_block) || die "can’t opendir $sys_block: $!";
my @bdevs = grep { /^(s|h)d./ && -d "$sys_block/$_" } readdir(DIR);
closedir DIR;

warn "# $hostname\n";
for (@bdevs) {
	my $device = $_;

	# get bayno
	my $bayletter = $device;
	$bayletter =~ s/^..(.).*/$1/;
	$dev{$device}{bayno} = 1 + ord($bayletter) - ord('a');

	$dev{$device}{mountpoint} = '' if (not defined($dev{$device}{mountpoint}));

	# Is this a hard drive or something removable (cdrom, etc)?
	$dev{$device}{removable} = 0;
	if (-e "/sys/block/$device/removable") {
		my $removable = `cat /sys/block/$device/removable` * 1;
		if ($removable) {
			$dev{$device}{removable} = 1;
			next;
		}
	}
	
	# Disk or partition?
	if ($device =~ /\d$/) {
		$dev{$device}{partition} = 1;
	} else {
		$dev{$device}{partition} = 0;
		# See if there are any partitions defined on this disk
		my @tmp = split("\n",`fdisk -l /dev/$device 2>/dev/null`);
		foreach (@tmp) {
			if (m,^/dev/(.*?)\s,) {
				push(@bdevs,$1);	# Let's add this one to our todo list
				$dev{$device}{partitions_found} = 1; # But make sure to mark that this device is already partitioned
			}
		}
	}

	# If it's a disk, are there any empty primary partitions, and is there unallocated space?
	if ($dev{$device}{partition} == 0) {
		my @tmp = split("\n",`sfdisk -l /dev/$device`);
		my $cnt = 0;
		my $last_cyl = 0;
		foreach (@tmp) {
			$dev{$device}{cylinders} = $1 if (/(\d+) cylinders,/);
			$dev{$device}{cylinder_size} = $1 if (/cylinders of (\d+) bytes,/);
			if (m,^/dev/(.*?)\s,) {
				$cnt++;
				my @tmp2 = split(/\s+/);
				if ($tmp2[$#tmp2] eq 'Empty') {
					$dev{$device}{next_available_primary_partition} = $cnt;
					$dev{$device}{next_available_cylinder} = $last_cyl+1;
					last;
				}
				$last_cyl = $tmp2[$#tmp2-4];
			}
		}	
	}

	# Size?
	my $size = `cat $sys_block/$_/size` * 512;	# We assume a blocksize of 512 bytes!
	$dev{$device}{size} = $size;
	warn "# $hostname -- $_: Size: $size\n" if ($DEBUG);

	# Valid partition table?
	# If this is a disk, does it have a valid partition table?
	if (!$dev{$device}{partition}) {
		my @fdisk = split("\n",`fdisk -l /dev/$device 2>&1 1>/dev/null`);
		$dev{$device}{valid_partition_table} = 1;
		foreach (@fdisk) {
			if (m,^Disk /dev/$device doesn.t contain a valid partition table,) {
				$dev{$device}{valid_partition_table} = 0;
			}
		}
	}

	# Partition type?
	# If this is a partition, see if we can determine the partition type. Note
	# that this will not work on a domU if the partition, not the entire device
	# is exported to the domU.
	if ($dev{$device}{partition}) {
		my $tmp = $device;
		$tmp =~ s/\d*$//;
		my @fdisk = split("\n",`fdisk -l /dev/$tmp`);
		foreach (@fdisk) {
			if (m,^/dev/$device,) {
				my @part_info = split (/\s+/, $_, 6);
				$dev{$device}{partition_type} = $part_info[4];
				warn "# $hostname -- $device: partition type $part_info[4]\n" if ($DEBUG);
			}
		}
	}

	# Filesystem?
	my $filesystem = `tune2fs -l /dev/$_ >/dev/null 2>&1; echo \$?` * 1;
	if ($filesystem == 0) {
		$dev{$device}{signature} = "ext3";
		warn "# $hostname -- $_: ext3\n" if ($DEBUG);
	} else {
		my $mdadm = `mdadm -E /dev/$_ >/dev/null 2>&1; echo \$?` * 1;
		if ($mdadm == 0) {
			$dev{$device}{signature} = "mdadm";
			warn "# $hostname -- $_ mdadm signature found\n" if ($DEBUG);
		}
	}
}

# Report on what we've found.
warn "# device:partition:valid_partition_table:partitions_found:cylinders:next_available_primary_partition:next_available_cylinder:size:partition_type:signature:mountpoint\n";
for (sort @bdevs) {
	my $device = $_;
	next if ($dev{$device}{removable}); # Ignore removable devices
	# Print results (purely informational)
	warn "# $device:$dev{$device}{partition}:$dev{$device}{valid_partition_table}:$dev{$device}{partitions_found}:" .
	     "$dev{$device}{cylinders}:$dev{$device}{next_available_primary_partition}:$dev{$device}{next_available_cylinder}:" .
	     "$dev{$device}{size}:$dev{$device}{partition_type}:$dev{$device}{signature}:$dev{$device}{mountpoint}\n";
}

# Now print out some shell code to do something with these devices
warn "\n# Output\n\n";
for (sort @bdevs) {
	my $device = $_;
	# First look at unpartitioned disks without a valid partition table
	if (not $dev{$device}{partition} and not $dev{$device}{valid_partition_table} and not $dev{$device}{partitions_found}) {
		warn "\n\n";
		warn "# $device is a drive that needs partitioning\n";
		warn "# $hostname -- fdisk /dev/$device && mkfs.ext3 -m 0 /dev/${device}1\n";
		print "(echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/$device && mkfs.ext3 -m 0 /dev/${device}1\n";
		$_ = "/dev/${device}1 1 2 " . ($disksize{$device}/1000) . " 83 Linux\n";
		warn "# $hostname -- $_";
		&add_to_mogilefs($hostname,$device,$mogroot,$nodeno,%dev);
		next;
	}
	# Then look at unformatted partitions at least 90G (that's a bit over 94,000,000 bytes) in size
	# We don't verify partition type here; we can't see that under a domU if just this partition is exported...
	# For sanity's sake we do verify that this partition is currently unmounted
	if ($dev{$device}{partition} and ($dev{$device}{signature} eq '') and ($dev{$device}{size} > 94000000) and ($dev{$device}{mountpoint} eq '')) {
		warn "\n\n";
		warn "# $device needs formatting\n";
		print "mkfs.ext3 -m 0 /dev/${device}\n";
		print "tune2fs -J0 -i0 /dev/${device}\n";
		&add_to_mogilefs($hostname,$device,$mogroot,$nodeno,%dev);
		next;
	}
	# Finally, look for drives with unallocated space...
	if (not $dev{$device}{partition} and ($dev{$device}{cylinders} > $dev{$device}{next_available_cylinder})) {
		my $size = $dev{$device}{cylinders} - $dev{$device}{next_available_cylinder};
		print "# $hostname -- add $device$dev{$device}{next_available_primary_partition}\n";
		print <<EOF;
(
 set -ex
 apt-get install -y parted
 echo $dev{$device}{next_available_cylinder},$size,83 | $sfdisk_command -N$dev{$device}{next_available_primary_partition} /dev/$device
 partprobe || true
 mkfs.ext3 -m 0 /dev/$device$dev{$device}{next_available_primary_partition}
 tune2fs -J0 -i0 /dev/$device$dev{$device}{next_available_primary_partition}
)
EOF
		$dev{"$device$dev{$device}{next_available_primary_partition}"}{bayno} = $dev{$device}{bayno};
		$dev{"$device$dev{$device}{next_available_primary_partition}"}{size} = $dev{$device}{cylinder_size} * $size;
		&add_to_mogilefs($hostname,"$device$dev{$device}{next_available_primary_partition}",$mogroot,$nodeno,%dev);
		next;
	}
}

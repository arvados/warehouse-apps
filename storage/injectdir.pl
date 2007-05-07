#!/usr/bin/perl

use strict;
use Digest::MD5 'md5_hex';
use HTTP::Request::Common;
use LWP::UserAgent;

if (@ARGV != 3)
{
    print STDERR <<EOF;
usage:
       $0 localdir keyprefix sshuser\@sshhost
       $0 localdir keyprefix http://host/path/to/uploadscripts
examples:
       $0 /tmp/RAW /foo_01/IMAGES/RAW moginject\@tomc
       $0 /tmp/RAW /foo_01/IMAGES/RAW http://tomc
EOF
;
    exit 1;
}

my ($dir, $keyprefix, $remote) = @ARGV;
for ($dir, $keyprefix)
{
    s,/*$,,;
}

chdir ($dir) or die "$0: Can't chdir to $dir: $!\n";

my $ua = LWP::UserAgent->new;
foreach my $file (`find . -type f`)
{
    chomp ($file);
    $file =~ s/^\.\///;

    my $key = $keyprefix . "/" . $file;

    my $data;
    do {
	local $/ = undef;
	open FILE, "<$file" or die "$0: Can't open $file: $!\n";
	$data = <FILE>;
	close FILE;
    };

    my $md5 = md5_hex($data);

    if ($remote =~ /^https?:\/\//)
    {
	my $r = $ua->request(POST $remote."/checkmd5.php",
			     [ "key" => $key ]);
	my $checkmd5 = $r->content;
	chomp ($checkmd5);
	if ($checkmd5 ne $md5)
	{
	    if ($checkmd5 eq "")
	    {
		print STDERR "new:     $md5 $key\n";
	    }
	    else
	    {
		print STDERR "update:  $md5 $key (was $checkmd5)\n";
	    }
	    my $r = $ua->request
		(POST $remote."/upload.php",
		 "Content-Type" => "form-data",
		 "Content"
		 => [ "key" => $key,
		      "md5" => $md5,
		      "upload"
		      => [ undef,
			   $file,
			   "Content-Type" => "application/binary",
			   "Content" => $data
			   ]
		      ]
		 );
	}
	else
	{
	    print STDERR "skip:    $md5 $key\n";
	}
    }
    else
    {
	print STDERR "via ssh: $md5 $key\n";
	open PIPE, "|ssh $remote" or die "$0: Can't start ssh: $!\n";
	print PIPE "$key\n";
	print PIPE "$md5\n";
	print PIPE $data;
	close PIPE;
    }
}

# arch-tag: Tom Clegg Tue May  1 11:24:32 PDT 2007 (align-call/injectdir.pl)

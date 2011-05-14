#!/usr/bin/perl

use strict;
use MogileFS::Client;
use LWP::UserAgent;

do '/etc/polony-tools/config.pl';

my @trackers = split (",", $ENV{MOGILEFS_TRACKERS});
my $domain = $ENV{MOGILEFS_DOMAIN};
my $mogc = MogileFS::Client->new (domain => $domain,
				  hosts => [@trackers]);

my $ua = LWP::UserAgent->new;
$ua->agent("polony-tools/0.0 ");

my ($rid, $nframes) = @ARGV;

FRAME: for (my $f=1; $f<=$nframes; $f++)
{
    my $fid = sprintf ("%04d", $f);
    my @urls = $mogc->get_paths("/$rid/frame/$fid");
    next FRAME if !@urls;
    my $attempt;
    for ($attempt=0; $attempt<6; $attempt++)
    {
	my $req = HTTP::Request->new(GET => $urls[0]);
	my $res = $ua->request($req);
	if ($res->is_success) {
	    $_ = $res->content;
	    s/^(\S*\s\S*\s\S*).*$/$1/gm;
	    s/^/$fid /gm;
	    print;
	    next FRAME;
	}
	if ($attempt > 0) { sleep($attempt); }
	unshift (@urls, pop (@urls));
    }
    $| = 1;
    die "Gave up on frame $f after $attempt attempts\n@urls";
}

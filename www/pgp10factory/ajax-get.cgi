#!/usr/bin/perl

use strict;
use CGI ':standard';
use CGI::Cookie;
use Digest::MD5 'md5_hex';
use Fcntl ':flock';
use POSIX;
do "session.pm";

my $workdir = "./cache";
mkdir $workdir;
chmod 0777, $workdir;
die "$workdir could not be created / is not writeable" unless -d $workdir && -w $workdir;

my $q = new CGI;
session::init($q);
print $q->header (-type => "text/plain",
		  -cookie => [session::togo()]);
my $sessionid = session::id();

my $what = $q->param ("what");
my $offer_none_option = $what =~ s/\?$//;
my $as = $q->param ("as");
die if $as ne "select";

my %todo;
opendir S, "./session/$sessionid";
for (sort (readdir S))
{
    next if /^\.\.?$/;
    if (/(.*)\.isurl$/)
    {
	my $datahash = readlink "$workdir/$1.stored";
	if (-e "$workdir/$datahash.is$what")
	{
	    $todo{$datahash} = 1;
	}
    }
    elsif (/^([0-9a-f]{32}(?:,[0-9a-f]{32})*)$/
	   && -e "$workdir/$1.is$what")
    {
	$todo{$_} = 1;
    }
}
closedir S;

print qq{<option value="">No $what</option>\n} if $offer_none_option;
for my $hash (sort keys %todo)
{
    my $shortname = $hash;
    $shortname =~ s/(.{8}).*/$1.../;

    my $comment = "";
    if (open (F, "<", "./session/$sessionid/$hash.comment") ||
	open (F, "<", "$workdir/$hash.comment"))
    {
	undef $/;
	$comment = <F>;
	$shortname = substr ($comment, 0, 32)." ($shortname)";
    }
    print qq{<option value="$hash">$shortname</option>\n};
}

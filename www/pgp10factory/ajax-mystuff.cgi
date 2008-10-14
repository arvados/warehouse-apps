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

print qq{<table style="background-color: #ddd; border-collapse: collapse; border: 1px solid #000;"><tr><td align="left" style="padding: 5px; border: 1px solid #000;">reads</td><td align="left" style="padding: 5px; border: 1px solid #000;">genomes</td><td align="left" style="padding: 5px; border: 1px solid #000;">pipelines</td><td align="left" style="padding: 5px; border: 1px solid #000;">unknown</td><td align="left" style="padding: 5px; border: 1px solid #000;">pending</td></tr>};

my %reads;
my %genomes;
my %pipelines;
my %unknown;
my %pending;
my @urls;

opendir S, "./session/$sessionid";
while ($_ = readdir S)
{
    next if /^\.\.?$/;
    if (/^([0-9a-f]{32}(?:,[0-9a-f]{32})*)(?:\.(.*))?$/) {
	my $hash = $1;
	my $ext = $2;
	my $datahash;
	if (!defined $ext)
	{
	    $datahash = $hash;
	}
	elsif ($ext eq "isurl")
	{
	    push @urls, $hash;
	    $datahash = readlink "$workdir/$hash.stored";
	}
	if ($datahash)
	{
	    if (-e "$workdir/$datahash.isreads")
	    {
		++$reads{$datahash};
	    }
	    elsif (-e "$workdir/$datahash.isgenome")
	    {
		++$genomes{$datahash};
	    }
	    elsif (-e "$workdir/$datahash.ispipeline")
	    {
		++$pipelines{$datahash};
	    }
	    else
	    {
		++$unknown{$datahash};
	    }
	}
	else
	{
	    ++$pending{$hash};
	}
    }
}
print qq{<tr>};
foreach (\%reads, \%genomes, \%pipelines, \%unknown, \%pending)
{
    my @hashes = sort keys %$_;
    if ($_ eq \%reads || $_ eq \%genomes)
    {
	my $what = $_ eq \%reads ? "reads" : "genome";
	map { s{^(.{8})(.*)(.{8})$}{qq{<a onclick="choose$what('$_');return false;" href="./?$_">$1}.($2?"...":$2).qq{$3</a>}}e } @hashes;
    }
    else
    {
	map { s{^(.{8})(.+)(.{8})$}{$1...$3} } @hashes;
    }
    print qq{<td valign="top" align="left" style="padding: 5px; border: 1px solid #000;">} . join (qq{<br />}, @hashes) . qq{</td>};
}
print qq{</tr>};

print qq{</table>};



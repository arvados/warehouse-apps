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

my %objects = (reads => {},
	       genomes => {},
	       pipelines => {},
	       unknown => {},
	       pending => {},
    );
my @urls;

my %todo;
opendir S, "./session/$sessionid";
for (sort (readdir S))
{
    next if /^\.\.?$/;
    if (/(.*)\.isurl$/)
    {
	my $datahash = readlink "$workdir/$1.stored";
	$todo{$datahash} = 1 if $datahash;
    }
    elsif (/^([0-9a-f]{32}(?:,[0-9a-f]{32})*)$/)
    {
	$todo{$_} = 1;
    }
}
closedir S;
for (sort keys %todo)
{
    next if /^\.\.?$/;
    if (/^([0-9a-f]{32}(?:,[0-9a-f]{32})*)$/) {
	my $hash = $1;
	my $datahash = $hash;
	if ($datahash)
	{
	    if (-e "$workdir/$datahash.isreads")
	    {
		++$objects{reads}->{$datahash};
	    }
	    elsif (-e "$workdir/$datahash.isgenome")
	    {
		++$objects{genomes}->{$datahash};
	    }
	    elsif (-e "$workdir/$datahash.isaffymap")
	    {
		++$objects{affymaps}->{$datahash};
	    }
	    elsif (-e "$workdir/$datahash.isaffyscan")
	    {
		++$objects{affyscans}->{$datahash};
	    }
	    elsif (-e "$workdir/$datahash.islayout")
	    {
		++$objects{layouts}->{$datahash};
	    }
	    elsif (-e "$workdir/$datahash.ispipeline")
	    {
		++$objects{pipelines}->{$datahash};
	    }
	    else
	    {
		++$objects{unknown}->{$datahash};
	    }
	}
	else
	{
	    ++$objects{pending}->{$hash};
	}
    }
}

print qq{<table class="manage_data">};

foreach my $obtype (qw(reads genomes affymaps affyscans layouts pipelines unknown pending))
{
    my @hashes = sort keys % { $objects{$obtype} };
    print qq{<tr><th colspan="4">$obtype</th></tr>};
    foreach my $label (@hashes)
    {
	my $datahash = $label;
	$label =~ s{^(.{35})(.+)$}{$1...};
	my $comment = "";
	if (open (F, "<", "./session/$sessionid/$datahash.comment") ||
	    open (F, "<", "$workdir/$datahash.comment"))
	{
	    local $/ = undef;
	    $comment = $q->escapeHTML (scalar <F>);
	}
	print qq{<tr><td>$label</td><td><input type="text" name="$datahash" id="$datahash" size=40 value="$comment" onpaste="showsavebutton('$datahash')" onkeypress="showsavebutton('$datahash')" /></td><td><button id="save-$datahash" style="display: none;" onclick="comment_save('$datahash')">Save</button><input type="hidden" id="hidden-$datahash" /></td></tr>\n};
    }
}
print qq{</table>};



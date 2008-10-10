#!/usr/bin/perl

use strict;
use CGI;
use Digest::MD5 'md5_hex';

my $workdir = "./cache";

print CGI->header;

print qq{<script language="javascript" type="text/javascript" src="prototype-1.6.0.3.js"></script>\n};
print qq{<script language="javascript" type="text/javascript" src="admin.js"></script>\n};

my %dataset;

opendir D, $workdir;
while (my $f = readdir D)
{
    if ($f =~ /^[0-9a-f]{32}(,[0-9a-f]{32})*$/)
    {
	my $url;
	if (open F, "<", "$workdir/$f.isurl")
	{
	    ($url) = <F>;
	    close F;
	    if (my $datahash = readlink "$workdir/$f.stored")
	    {
		$dataset{$datahash} ||= {};
		$dataset{$datahash}->{sources} ||= [];
		push @ { $dataset{$datahash}->{sources} }, $url;
	    }
	}
	else
	{
	    my $datahash = $f;
	    $dataset{$datahash} ||= {};
	    if (open F, "<", "$workdir/$f.comment")
	    {
		local $/ = undef;
		$dataset{$datahash}->{comment} = <F>;
	    }
	}
    }
}

print qq{<table>\n};
print qq{<tr><td><b>data set</b></td><td><b>comment</b></td></tr>\n};
for my $datahash (sort keys %dataset)
{
    print qq{<tr><td valign="top"><code>};
    print qq{<a href="./?$datahash">};
    print CGI->escapeHTML(substr($datahash,0,33));
    print qq{</a>};
    print qq{</code></td><td valign="top">};
    my $qcomment = CGI->escapeHTML($dataset{$datahash}->{comment});
    my $commenthash = md5_hex ($dataset{$datahash}->{comment});
    print qq{<textarea rows="3" cols="50" id="$datahash" name="$datahash-$commenthash" onpaste="showsavebutton('$datahash')" onkeypress="showsavebutton('$datahash')">$qcomment</textarea>};
    print qq{<br /><button style="display: none;" id="save-$datahash" onclick="do_save('$datahash')">Save</button>};
    print qq{<span style="color: #777;"><pre>}, join ("\n", "Downloaded from:", map { CGI->escapeHTML(scrub_auth($_)) } @{$dataset{$datahash}->{sources}}), qq{</pre></span>}
    if $dataset{$datahash}->{sources};
    print qq{</td></tr>\n};
}
print qq{</table>\n};

sub scrub_auth
{
    local $_ = shift;
    s{^([^/]+//)[^/]+\@}{$1***:***\@};
    $_;
}

#!/usr/bin/perl

use strict;
use CGI;
use Digest::MD5 'md5_hex';

my $workdir = "./cache";

print CGI->header;

print qq{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252" />
<title>pgp10factory admin</title>
<script language="javascript" type="text/javascript" src="prototype-1.6.0.3.js"></script>
<script language="javascript" type="text/javascript" src="admin.js"></script>
</head><body>
<h1>PGP-10 Factory - Admin</h1>
};

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
	elsif (-e "$workdir/$f.isreads" || -e "$workdir/$f.isgenome" || -e "$workdir/$f.isaffyscan" || -e "$workdir/$f.isaffymap" || -e "$workdir/$f.issnplist" || -e "$workdir/$f.islayout")
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
    next unless -e "$workdir/$datahash.isreads" || "$workdir/$datahash.isgenome";
    print qq{<tr><td valign="top"><code>};
    print qq{<a href="./?$datahash">};
    print CGI->escapeHTML(substr($datahash,0,33));
    print qq{</a>};
    print qq{</code></td><td valign="top">};
    my $qcomment = CGI->escapeHTML($dataset{$datahash}->{comment});
    my $commenthash = md5_hex ($dataset{$datahash}->{comment});
    print qq{<textarea rows="3" cols="50" id="$datahash" name="$datahash-$commenthash" onpaste="showsavebutton('$datahash')" onkeypress="showsavebutton('$datahash')">$qcomment</textarea>};
    print qq{<br /><button style="display: none;" id="save-$datahash" onclick="do_save('$datahash')">Save</button>};
    print qq{<span style="color: #777;"><pre>}, join ("\n", "Downloaded from:", map { CGI->escapeHTML(scrub_auth($_)) } grep { /\S/ } (@{$dataset{$datahash}->{sources}})[0..5]), qq{</pre></span>}
    if $dataset{$datahash}->{sources};
    print qq{</td></tr>\n};
}

print qq{
</table>
</body>
</html>
};

sub scrub_auth
{
    local $_ = shift;
    s{^([^/]+//)[^/]+\@}{$1***:***\@};
    $_;
}

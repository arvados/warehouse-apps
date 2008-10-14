#!/usr/bin/perl

use strict;
use CGI;
use Digest::MD5 'md5_hex';
do "session.pm";

my $workdir = "./cache";

my $q = new CGI;
session::init($q);
my $sessionid = session::id();
print CGI->header (-cookie => [session::togo()]);

print qq{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252" />
<title>pgp10factory home</title>
<link href="style.css" rel="stylesheet" type="text/css" />
<script language="javascript" type="text/javascript" src="prototype-1.6.0.3.js"</script>
<script language="javascript" type="text/javascript" src="pipeline_render.js"></script>
<script language="javascript" type="text/javascript" src="home.js"></script>
</head><body>
<div style="width: 625px; text-align: left;">
<h1>PGP-10 Factory - Home</h1>

<p>Paste a URL to download data via http or https:<br />
<input name="url" type="text" id="url" value="" size="50" />
<button onclick="download_button()">Download to warehouse</button>
<br />Use "http://user:password\@host/path/file" if the server requires HTTP authentication.
</p>

<p>Paste an MD5 signature to add warehouse data to your stuff below:<br />
<input name="hash" type="text" id="hash" value="" size="50" />
<button onclick="addexisting_button()">Add to my session</button>
</p>

<input name="requestid" type="hidden" id="requestid" />
<div style="clear: both;"></div><br />
<div id="info_window" align="center">
<p id="info_content"></p>
</div>
<div id="mystuff"></div>
<div id="pipeline" style="clear: both;">
<p>
<input id="wantreads" name="reads" size="50" /> reads<br />
<input id="wantgenome" name="reads" size="50" /> genome<br />
<button onclick="pipeline_submit();">View results</button>
</p>
<table><tr><td><p id="pipeline_id"></p></td></tr>
<tr><td><p id="pipeline_message"></p></td></tr>
<tr><td><div id="result_content"></div></td></tr>
</table>
</div>
</div>
</body>
</html>
};

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

<input type="hidden" id="panel_showhide" value="download">

<table id="toptabs"><tr><th width="1"><a href="#" onclick="panel_showhide('download');">Download/Import</a></th><th width="1"><a href="#" onclick="panel_showhide('manage');">Manage&nbsp;Data</a></th><th width="1"><a href="#" onclick="panel_showhide('build');">Build&nbsp;Pipelines</a></th><th width="*" style="background-color: #fff; border: none;"></th></tr>
<tr><td colspan="4">

<div id="panel_download">

<p>Paste a URL to download data via http or https:<br />
<input name="url" type="text" id="url" value="" size="50" /><button onclick="download_button()">Download to warehouse</button>
<br />Use "http://user:password\@host/path/file" if the server requires HTTP authentication.
</p>

<input name="requestid" type="hidden" id="requestid" />
<div style="clear: both;"></div><br />
<div id="info_window" align="center">
<p id="info_content"></p>
</div>

<p>Paste an MD5 signature to add warehouse data to your stuff below:<br />
<input name="hash" type="text" id="hash" value="" size="50" /><button onclick="addexisting_button()">Add to my session</button>
</p>


</div>
<div id="panel_manage" style="display: none;">

<div id="mystuff"></div>

</div>
<div id="panel_build" style="display: none;">


<div id="pipeline" style="clear: both;">
<p>
<select id="selectreads" name="reads" size="1" onclick="select_populate('selectreads', 'reads')"><option value="">Select reads</option></select><br />
<select id="selectgenome" name="genome" size="1" onclick="select_populate('selectgenome', 'genome')"><option value="">Select genome</option></select><br />
<button onclick="pipeline_submit();">View results</button>
</p>
<table><tr><td><p id="pipeline_id"></p></td></tr>
<tr><td><p id="pipeline_message"></p></td></tr>
<tr><td><div id="result_content"></div></td></tr>
</table>
</div>

</div>
</td></tr></table>

</div>
</body>
</html>
};

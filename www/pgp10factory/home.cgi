#!/usr/bin/perl

use strict;
use CGI;
use Digest::MD5 'md5_hex';
use POSIX;
do "session.pm";

my $workdir = "./cache";

my $q = new CGI;
session::init($q);
my $sessionid = session::id();
print CGI->header (-cookie => [session::togo()]);

my $layout_stash = "";
if ($ENV{QUERY_STRING} =~ /^([0-9a-f]{32})$/ &&
    -e "$workdir/$1.islayout" &&
    open F, "<", "$workdir/$1")
{
    local $/ = undef;
    $layout_stash = scalar <F>;
    while ($layout_stash =~ /([0-9a-f]{32}(,[0-9a-f]{32})*)/g)
    {
	sysopen F, "./session/$sessionid/$1", O_WRONLY|O_CREAT|O_EXCL;
    }
    $layout_stash = $q->escapeHTML ($layout_stash);
    close F;
}

print qq{
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252" />
<title>pgp10factory home</title>
<link href="style.css" rel="stylesheet" type="text/css" />
<script language="javascript" type="text/javascript" src="prototype-1.6.0.3.js"></script>
<script language="javascript" type="text/javascript" src="sha1.js"></script>
<script language="javascript" type="text/javascript" src="pipeline_render.js"></script>
<script language="javascript" type="text/javascript" src="home.js"></script>
</head><body>
<div style="width: 625px; text-align: left;">
<h1>PGP-10 Factory - Home</h1>

<input type="hidden" id="panel_showhide" value="download">

<table class="toptabs"><tr><th id="tab_download" width="1"><a href="#" onclick="panel_showhide('download');">Download/Import</a></th><th id="tab_manage" width="1"><a href="#" onclick="panel_showhide('manage');">Manage&nbsp;Data</a></th><th id="tab_build" width="1"><a href="#" onclick="panel_showhide('build');">Build&nbsp;Pipelines</a></th><th width="*" style="background-color: #fff; border-top: none; border-right: none;"></th></tr>
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
<button onclick="fewerpipelines();">Fewer pipelines</button>
<button onclick="morepipelines();">More pipelines</button>
<input type="hidden" id="layout_stash" name="layout_stash" value="$layout_stash" />
<button onclick="pipeline_layout_save();" id="layout_save">Save this layout</button>
<p style="display: inline;" id="layout_link"></p>
<br />
<table><tr>
};
for (my $PID = 0; $PID < 16; $PID++)
{
    my $hiddenstyle = $PID >= 3 ? qq{ style="display: none;"} : "";
    print qq{
<td valign="top" id="pipeline_cell_$PID"$hiddenstyle>
<p>
<select id="selectreads_$PID" name="reads_$PID" size="1" onclick="select_populate($PID, 'reads');" onchange="enable_updatebutton($PID);"><option value="">Select reads</option></select><br />
<select id="selectgenome_$PID" name="genome_$PID" size="1" onclick="select_populate($PID, 'genome');" onchange="enable_updatebutton($PID);"><option value="">Select genome</option></select><br />
<input type="hidden" id="selectedreads_$PID" name="selectedreads_$PID" />
<input type="hidden" id="selectedgenome_$PID" name="selectedgenome_$PID" />
<input type="hidden" id="renderhash_$PID" name="renderhash_$PID" />
<button id="updatebutton_$PID" onclick="pipeline_submit($PID);">Update</button>
</p>
<div class="workflow">
<table id="pipelinejobs_$PID"><tr><td><p id="pipeline_id_$PID"></p></td></tr>
<tr><td><p id="pipeline_message_$PID"></p></td></tr>
<tr><td><div id="result_content_$PID"></div></td></tr>
</table>
</div>
</td>
};
}

print qq{
</tr></table>
</div>

</div>
</td></tr></table>

</div>
</body>
</html>
};

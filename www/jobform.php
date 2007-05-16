<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';
$source = escapeshellarg($svn_repos);

$dsid = $_REQUEST[dsid];
$cid = $_REQUEST[cid];

if (!is_array($cid))
{
  if (isset($cid))
    {
      $cid = array($cid);
    }
  else
    {
      $cid = array();
    }
}

?>
<html>
<head><title><?=htmlspecialchars($dsid)?> job knobs</title></head>
<body>
<h1><a href="./"><?=htmlspecialchars(trim(`hostname`))?></a> / job knobs for <?=htmlspecialchars($dsid)?> job</h1>

<form method=post action="jobsubmit.php">
<table>

<tr>
 <td valign=top>Dataset</td>
 <td valign=top><?=htmlspecialchars($dsid)?></td>
</tr>
<input type=hidden name="dsid" value="<?=htmlspecialchars($dsid)?>">

<tr>
 <td valign=top>Cycles</td>
 <td valign=top><?=nl2br(htmlspecialchars(join("\n",$cid)))?></td>
</tr>
<input type=hidden name="cid[]" value="<?=join("\">\n<input type=hidden name=\"cid[]\" value=\"", $cid)?>">

<tr>
 <td valign=top>knobs</td>
 <td><textarea name="knobs" wrap="none" cols="80" rows="7">FOCUSPIXELS=
ALIGNWINDOW=
OBJECTTHRESHOLD=</textarea>
</tr>

<tr>
 <td valign=top>Revision</td>
 <td valign=top><select size=8 name=revision><?php

$nnodes = 0;
foreach(explode("\n", `sinfo --noheader --format=%D`) as $n)
{
  $nnodes += $n;
}
$listall = `srun --immediate --overcommit -N$nnodes --chdir=/tmp sh -c 'ls -d1 /usr/local/polony-tools/*/.tested'`;
foreach (explode ("\n", $listall) as $rev)
{
  if (ereg("/([0-9]+)/\.tested$", $rev, $regs))
    {
      $tested[$regs[1]]++;
    }
}
$log = `svn log $source`;
$selected = "selected";
foreach (explode("------------------------------------------------------------------------\n", $log) as $logentry)
{
  if (ereg ("^r([0-9]+)", $logentry, $regs))
    {
      $revision = $regs[1];
      $installed = "";
      if ($tested[$revision] == $nnodes)
	{
	  $installed = "(*)";
	}
      list ($line1, $msg) = explode ("\n\n", $logentry, 2);
      list ($x, $committer, $date, $x) = explode (" | ", $line1);
      $date = ereg_replace (" \(.*", "", $date);
      echo "\n<option value=\"$revision\" $selected>".htmlspecialchars("r$revision $date ($committer) $msg $installed")."</option>";
      $selected = "";
    }
}

?></select></td>

<tr>
 <td></td>
 <td><input type=submit value="Start">  Just click once!  It might take a few seconds before you get any feedback.</td>
</tr>

</table>
</form>

</body>
</html>

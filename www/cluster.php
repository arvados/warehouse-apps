<?php

require_once 'inc-mogilefs.php';
$domain = isset($_REQUEST['domain'])? $_REQUEST['domain'] : "default";
$grok = array();

function grok ($fid=undef, $length=undef, $dkey=undef)
{
  global $grok;
  if ($fid !== undef)
    {
      $dkey = explode("/", ereg_replace("^/*","",$dkey));
      $subdir = $dkey[count($dkey)-2];
      $dataset = $dkey[0];
      if (!isset($grok[$dataset]))
	{
	  $grok[$dataset] = array();
	}
      if (!isset($grok[$dataset][$subdir]))
	{
	  $grok[$dataset][$subdir] = array();
	  $grok[$dataset][$subdir][length] = 0;
	  $grok[$dataset][$subdir][count] = 0;
	}
      $grok[$dataset][$subdir][length] += $length;
      $grok[$dataset][$subdir][count] ++;
    }
  else
    {
      echo "<table>\n";
      echo "<tr><th align=left>dataset</th><th align=left>base</th><th align=left>files</th><th align=left>bytes</th></tr>\n";
      foreach ($grok as $dataset => $d)
	{
	  echo "<tr><td>$dataset</td></tr>\n";
	  foreach ($d as $subdir => $s)
	    {
	      echo "<tr><td></td><td>$subdir</td><td>$s[count]</td><td>$s[length]</td></tr>\n";
	    }
	}
      echo "</table>\n";
    }
}

$keyprefix = $_REQUEST['keyprefix'];
$q = mysql_query("select
     file.fid,
     file.length,
     file.dkey
     from file
     left join domain on domain.dmid=file.dmid
     where dkey like '$keyprefix%'
     and domain.namespace='$domain'
     order by dkey");
echo mysql_error();
$lastfid = -1;
while($row = mysql_fetch_row($q))
{
  list ($fid, $length, $dkey) = $row;
  if ($fid == $lastfid) continue;
  $lastfid = $fid;
  grok($fid, $length, $dkey);
}
grok();

echo "<PRE>";
echo htmlspecialchars(`mogadm check`);
echo "</PRE>\n";

// arch-tag: b76f244a-fd8f-11db-9207-0015f2b17887
?>

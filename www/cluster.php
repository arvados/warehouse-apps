<?php

require_once 'inc-mogilefs.php';
$domain = isset($_REQUEST['domain'])? $_REQUEST['domain'] : "default";
$grok = array();
$lengthtotal = 0;

function insertcommas ($n)
{
  while (ereg("[0-9][0-9][0-9][0-9]", $n))
    {
      $n = ereg_replace ("([0-9]+)([0-9][0-9][0-9])", "\\1,\\2", $n);
    }
  return $n;
}

function grok ($fid=undef, $length=undef, $dmid=undef, $dkey=undef)
{
  global $grok;
  global $lengthtotal;
  global $namespace;
  if ($fid !== undef)
    {
      $dkey = explode("/", ereg_replace("^/*","",$dkey));
      $subdir = $dkey[count($dkey)-2];
      $dataset = "[".$namespace[$dmid]."]".$dkey[0];
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
      $lengthtotal += $length;
    }
  else
    {
      echo "<div style=\"font-size: 9pt;\">\n";
      echo "<table cellspacing=0 cellpadding=0 border=0>\n";
      echo "<tr><th align=left>dataset</th><th align=left>cycle</th><th align=right>&nbsp;files&nbsp;</th><th align=right>bytes</th></tr>\n";
      foreach ($grok as $dataset => $d)
	{
	  $stfiles = 0;
	  $stbytes = 0;
	  echo "<tr><td>$dataset</td></tr>\n";
	  foreach ($d as $subdir => $s)
	    {
	      echo "<tr><td></td><td>$subdir</td><td align=right>&nbsp;"
		.insertcommas($s[count])
		."&nbsp;</td><td align=right>"
		.insertcommas($s[length])
		."</td></tr>\n";
	      $stfiles += $s[count];
	      $stbytes += $s[length];
	    }
	  echo "<tr><td></td><td></td><td align=right><i>&nbsp;"
	    .insertcommas($stfiles)
	    ."&nbsp;</i></td><td align=right><i>"
	    .insertcommas($stbytes)
	    ."</i></td></tr>\n";
	}
      echo "<th align=left>total</th><td></td><td></td><td align=right><i><b>"
	.insertcommas($lengthtotal)
	."</b></i></td></tr>\n";
      echo "</table>\n";
      echO "</div>\n";
    }
}

$namespace = array();
$q = mysql_query("select dmid,namespace from domain");
while ($row = mysql_fetch_row($q))
{
  $namespace[$row[0]] = $row[1];
}

$q = mysql_query("select
     file.fid,
     file.length,
     file.dmid,
     file.dkey
     from file
     order by dmid,dkey");
echo mysql_error();
$lastfid = -1;
while($row = mysql_fetch_row($q))
{
  list ($fid, $length, $dmid, $dkey) = $row;
  if ($fid == $lastfid) continue;
  $lastfid = $fid;
  grok($fid, $length, $dmid, $dkey);
}
grok();

echo "<PRE>";
echo htmlspecialchars(`mogadm check`);
echo "</PRE>\n";

// arch-tag: b76f244a-fd8f-11db-9207-0015f2b17887
?>

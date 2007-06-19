<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

putenv("MOGILEFS_DOMAIN=images");
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

$dsid = $_REQUEST[dsid];
$frame = 0 + $_REQUEST[frame];

$ext = explode(" ", "tif tif.gz raw raw.gz");
$extcount = 4;
$e0 = 0;

$q = mysql_query("select *
 from cycle
 left join dataset on cycle.dsid=dataset.dsid
 where cycle.dsid='$dsid'
 order by cid");
while ($row = mysql_fetch_assoc ($q))
{
  $cid = $row[cid];
  if ($cid == '999')
    {
      $prefix = "WL";
    }
  else
    {
      $prefix = "SC";
    }
  if ($row[nfiles] == $row[nframes])
    {
      $startimage = $frame;
      $stopimage = $frame;
    }
  else if ($row[nfiles] > $row[nframes])
    {
      $startimage = $frame * 4 - 3;
      $stopimage = $frame * 4;
    }
  for ($i=$startimage; $i<=$stopimage; $i++)
    {
      $fileid = sprintf ("%04d", $i);
      for ($e = 0; $e < 1 || $e < $extcount; $e++)
	{
	  $dkey = "/$dsid/IMAGES/RAW/$cid/{$prefix}_{$fileid}.".$ext[($e0+$e)%$extcount];
	  $url = trim (`perl moggetpaths.pl $dkey`);
	  if ($url)
	    {
	      $e0 = $e;
	      echo "<a href=\"get.php?domain=images&dkey=$dkey&format=png\">$dkey</a><br>\n";
	      break;
	    }
	}
    }
}

?>

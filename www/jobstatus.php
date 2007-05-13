<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

putenv("MOGILEFS_DOMAIN=reports");
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

$rid = $_REQUEST[rid] + 0;
if ($rid)
{
  $where = "where rid='$rid'";
}
else
{
  $where = "";
}

foreach (explode("\n", trim(`squeue|sort -n`)) as $sj)
{
  $sj = explode(" ", ereg_replace (" +", " ", trim($sj)));
  $squeue[$sj[0]] = $sj[4];
}

$njobs = 0;
$njobs_running = 0;
$q = mysql_query ("select * from job $where order by sjid");
while ($row = mysql_fetch_assoc ($q))
{
  ++$njobs;
  if (isset($squeue[$row[sjid]]))
    {
      ++$njobs_queued;
      if (ereg("R", $squeue[$row[sjid]]))
	{
	  ++$njobs_running;
	}
    }
}

$elapsed = mysql_one_value("select unix_timestamp(max(finished))-unix_timestamp(min(submittime)) from job $where");

?>
<html>
<head><title><?=htmlspecialchars("jobs $where")?></title></head>
<body>
<h1><a href="./"><?=htmlspecialchars(trim(`hostname`))?></a> / <?=htmlspecialchars("jobs $where")?></h1>

<table>
<tr>
  <td align=right>total jobs</td><td><?=$njobs?></td>
</tr><tr>
  <td align=right>running jobs</td><td><?=$njobs_running?></td>
</tr><tr>
  <td align=right>waiting jobs</td><td><?=$njobs_queued-$njobs_running?></td>
</tr><tr>
  <td align=right>elapsed</td><td><?=$elapsed?>s</td>
</tr>
</table>

<table>
<tr>
  <td>frame</td>
  <td>stdout#lines</td>
  <td>stderr#lines</td>
  <td>seconds</td>
</tr>
<?php

$q = mysql_query("select *, floor(finished-submittime) sec
 from job
 $where
 order by fid");
while ($row = mysql_fetch_assoc($q))
{
  echo "<tr>";
  echo "<td>$row[fid]</td>";
  if ($row[finished])
    {
      echo "<td><a href=\"get.php?domain=reports&dkey=".htmlspecialchars($row[dkey_stdout])."\">".ereg_replace(" .*","",$row[wc_stdout])."</a></td>\n";
      echo "<td><a href=\"get.php?domain=reports&dkey=".htmlspecialchars($row[dkey_stderr])."\">".ereg_replace(" .*","",$row[wc_stderr])."</a></td>\n";
      echo "<td>$row[sec]</td>\n";
    }
  echo "</tr>\n";
}

?>
</table>

</body>
</html>

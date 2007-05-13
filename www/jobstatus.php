<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

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
  else
    {
      if (!isset($row[finished]))
	{
	  mysql_query("update job set finished=now() where jid='$row[jid]'");
	}
    }
}

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
</tr>
</table>
</body>
</html>

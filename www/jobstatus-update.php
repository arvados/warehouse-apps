<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

lock_or_exit("jobstatus");

putenv("MOGILEFS_DOMAIN=reports");
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

foreach (explode("\n", trim(`squeue|sort -n`)) as $sj)
{
  $sj = explode(" ", ereg_replace (" +", " ", trim($sj)));
  $squeue[$sj[0]] = $sj[4];
}

$q = mysql_query ("select * from job where finished is null order by sjid");
while ($row = mysql_fetch_assoc ($q))
{
  if (!isset($squeue[$row[sjid]]))
    {
      $stdout = escapeshellarg(trim(`./moggetpaths $row[dkey_stdout]`));
      $wc_stdout = trim(`wget -O - -q $stdout | wc`);
      $stderr = escapeshellarg(trim(`./moggetpaths $row[dkey_stderr]`));
      $wc_stderr = trim(`wget -O - -q $stderr | wc`);
      mysql_query("update job set
	finished=now(),
	wc_stdout='$wc_stdout',
	wc_stderr='$wc_stderr'
	where jid='$row[jid]'");
    }
}

?>

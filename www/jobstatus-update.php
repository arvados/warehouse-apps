<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

lock_or_exit("jobstatus");

putenv("MOGILEFS_DOMAIN=reports");
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

// check for finished jobs and record finish times & output size in mysql table

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
      $stdout = trim(`./moggetpaths $row[dkey_stdout]`);
      if ($stdout == "") { $wc_stdout = "null"; }
      else
	{
	  $stdout = escapeshellarg($stdout);
	  $wc_stdout = trim(`wget -O - -q $stdout | wc`);
	  $wc_stdout = "'$wc_stdout'";
	}
      $stderr = trim(`./moggetpaths $row[dkey_stderr]`);
      if ($stderr == "") { $wc_stderr = "null"; }
      else
	{
	  $stderr = escapeshellarg($stderr);
	  $wc_stderr = trim(`wget -O - -q $stderr | wc`);
	  $wc_stderr = "'$wc_stderr'";
	}
      if ($wc_stderr == "null" || $wc_stdout == "null")
	{
	  mysql_query("update job set
		sjid=null,
		submittime=null
		where jid='$row[jid]'");
	  echo sprintf("%8d apparently failed\n", $row[jid]);
	}
      else
	{
	  mysql_query("update job set
		finished=now(),
		wc_stdout=$wc_stdout,
		wc_stderr=$wc_stderr
		where jid='$row[jid]'");
	  echo sprintf("%8d 32s %32s\n", $row[jid], $wc_stdout, $wc_stderr);
	}
    }
}

// check for unsubmitted or re-queued jobs and submit them to slurm queue

$q = mysql_query ("select * from job
 left join report on report.rid=job.rid
 where sjid is null");
while ($row = mysql_fetch_assoc ($q))
{
  foreach (split ("\n", $row[knobs]) as $knob)
    {
      $knob = trim($knob);
      putenv("USER_".$knob);
    }
  $revisiondir = "/usr/local/polony-tools/$row[revision]";
  putenv ("REVISION=".$row[revision]);
  putenv ("REVISIONDIR=".$revisiondir);
  putenv ("BASEORDER=".$row[baseorder]);
  putenv ("OUTPUT_TRACKERS=".join(",",$mogilefs_trackers));
  putenv ("OUTPUT_DOMAIN=reports");
  putenv ("OUTPUT_CLASS=reports");
  putenv ("DATASETDIR=mogilefs:///$row[dsid]");
  putenv ("MOGILEFS_DOMAIN=images");
  putenv ("MOGILEFS_TRACKERS=".join(",",$mogilefs_trackers));
  putenv ("PATH=$revisiondir/src/align-call:$revisiondir/install/bin:".getenv("PATH"));
  putenv("FRAMENUMBER=$row[fid]");
  putenv("OUTPUT_KEY=$row[dkey_stdout]");
  $cmdout = `$row[cmd] 2>&1`;
  ereg("srun: jobid ([0-9]+) submitted", $cmdout, $regs);
  $sjid = $regs[1];
  mysql_query ("update job set sjid='$sjid', submittime=now(), finished=null where jid='$row[jid]'");
  echo "Submitted slurm job jobid=$sjid for my job jid=$row[jid]\n";
}

?>

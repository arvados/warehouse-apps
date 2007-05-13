<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

$dsid = $_POST[dsid];

mysql_query("create table if not exists report
(
 rid bigint not null auto_increment primary key,
 dsid char(32),
 baseorder varchar(255),
 knobs text
)");

mysql_query("create table if not exists job
(
 jid bigint not null auto_increment primary key,
 sjid bigint,
 rid bigint references report.rid,
 fid char(4),
 dkey_stdout char(32),
 dkey_stderr char(32),
 wc_stdout char(32),
 wc_stderr char(32),
 cmd text,
 submittime datetime,
 finished datetime
)");

$nframes = mysql_one_value ("select nframes from dataset where dsid='$dsid'");

echo "<p>Job will run on $nframes frames.\n";
for($i=0; $i<1024; $i++) { echo "    "; } echo "\n";
flush();

mysql_query("insert into report set
 dsid='".addslashes($dsid)."',
 baseorder='".addslashes(join(",",$_POST[cid]))."',
 knobs='".addslashes($_POST[knobs])."'");
$rid = mysql_insert_id();
if(!$rid)
{
  echo "Error inserting new row in report table: ".mysql_error();
  exit;
}

foreach (split ("\n", $_POST[knobs]) as $knob)
{
  $knob = trim($knob);
  putenv("USER_".$knob);
}
putenv ("BASEORDER=".join(",", $_POST[cid]));

putenv ("OUTPUT_TRACKERS=".join(",",$mogilefs_trackers));
putenv ("OUTPUT_DOMAIN=reports");
putenv ("OUTPUT_CLASS=reports");
putenv ("DATASETDIR=mogilefs:///$dsid");
putenv ("MOGILEFS_DOMAIN=images");
putenv ("MOGILEFS_TRACKERS=".join(",",$mogilefs_trackers));
putenv ("PATH=/tmp/polony-tools/src/align-call:/tmp/polony-tools/install/bin:".getenv("PATH"));

echo "<p>Submitting jobs.\n<p>";
flush();

for ($f=1; $f<=$nframes; $f++)
{
  $fid = sprintf ("%04d", $f);
  $dkey_stdout="/$rid/frame/$fid";
  $dkey_stderr="/$rid/frame/$fid.stderr";
  putenv("FRAMENUMBER=$fid");
  putenv("OUTPUT_KEY=$dkey_stdout");
  $cmd = "srun -b -D /tmp/polony-tools -o /tmp/stdout -e /tmp/stderr `pwd`/../align-call/oneframe.sh";
  $cmdout = `$cmd 2>&1`;
  ereg("srun: jobid ([0-9]+) submitted", $cmdout, $regs);
  $sjid = $regs[1];
  mysql_query ("insert into job set
 jid=null,
 sjid='$sjid',
 rid='$rid',
 fid='$fid',
 dkey_stdout='$dkey_stdout',
 dkey_stderr='$dkey_stderr',
 cmd='".addslashes($cmd)."',
 submittime=now()");
  echo ".";
  if ($f % 80 == 0) echo "<br>\n";
  flush();
}

?>

<p>Finished.
<p>You may proceed to the
<a href="jobstatus.php?rid=<?=$rid?>">job <?=$rid?> status</a>
page.

</body>
</html>

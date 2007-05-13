<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

$dsid = $_REQUEST[dsid];
$cid = $_REQUEST[cid];

mysql_query("create table if not exists report
(
 rid bigint not null auto_increment primary key
)");

mysql_query("create table if not exists job
(
 jid bigint not null auto_increment primary key,
 sjid bigint,
 rid bigint references report.rid,
 fid char(4),
 cmd text,
 submittime datetime
)");

$nframes = mysql_one_value ("select nframes from dataset where dsid='$dsid'");

mysql_query("insert into report set rid=null");
$rid = mysql_insert_id();
if(!$rid)
{
  echo "Error inserting new row in report table: ".mysql_error();
  exit;
}

for ($f=1; $f<=$nframes && $f<20; $f++)
{
  $fid = sprintf ("%04d", $f);
  $cmd = "FRAMENUMBER=$fid \
 OUTPUT_TRACKERS=".escapeshellarg(join(",",$mogilefs_trackers))." \
 OUTPUT_DOMAIN=reports \
 OUTPUT_CLASS=reports \
 OUTPUT_KEY=/$rid/frame/$fid \
 DATASETDIR=mogilefs:///$dsid \
 MOGILEFS_DOMAIN=images \
 MOGILEFS_TRACKERS=tomc:6001 \
 BASEORDER=".escapeshellarg(join(",",$cid))." \
 FOCUSPIXELS=4000 \
 ALIGNWINDOW=15 \
 OBJECTTHRESHOLD=9000 \
 SORTEDTAGS=\"\" \
 PATH=\"/tmp/polony-tools/src/align-call:/tmp/polony-tools/install/bin:\$PATH\" \
 srun -D /tmp/polony-tools -b /tmp/polony-tools/src/align-call/oneframe.sh";
  $cmdout = `$cmd 2>&1`;
  ereg("srun: jobid ([0-9]+) submitted", $cmdout, $regs);
  $sjid = $regs[1];
  mysql_query ("insert into job set
 jid=null,
 sjid='$sjid',
 rid='$rid',
 fid='$fid',
 cmd='$cmd',
 submittime=now()");
  $jid = mysql_insert_id();
  echo "job: $jid $sjid $rid $fid<br>";
}

header("Location: ./dataset.php?dsid=".urlencode($dsid));
exit;
?>

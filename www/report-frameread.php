<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

putenv("MOGILEFS_DOMAIN=reports");
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

$rid = $_REQUEST[rid] + 0;

$nframes = mysql_one_value ("select max(fid)+0 from job where rid='$rid'");

if ($_REQUEST[gz])
{
  $filter = "| gzip";
  header ("Content-Type: application/octet-stream");
  header ("Content-Disposition: attachment; filename=\"allreads-job$rid.txt.gz\"");
}
elsif ($_REQUEST[md5])
{
  $filter = "| md5sum";
  header ("Content-Type: text/plain");
}
else
{
  $filter = "";
  header ("Content-Type: text/plain");
  header ("Content-Disposition: attachment; filename=\"allreads-job$rid.txt\"");
}

flush();

passthru ("(perl report-frameread.pl $rid $nframes $filter) 2>&1");
?>

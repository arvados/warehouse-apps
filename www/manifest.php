<?php

header("Content-type: text/plain");
set_time_limit($_REQUEST['recompute_all_md5'] ? 86400 : 120);

require_once 'inc-mogilefs.php';
$domain = isset($_REQUEST['domain'])? $_REQUEST['domain'] : "default";

list ($dmid) = mysql_fetch_row (mysql_query ("select dmid from domain where namespace='$domain'"));

$keyprefix = $_REQUEST['keyprefix'];
$q = mysql_query("select
     file.fid,
     file.length,
     file.dkey,
     md5,
     hostip, http_port, device.devid
     from file
     left join file_on on file_on.fid=file.fid
     left join device on device.devid=file_on.devid
     left join host on host.hostid=device.hostid
     left outer join md5 on md5.fid=file.fid
     where dmid='$dmid'
     and dkey like '$keyprefix%'");
echo mysql_error();
$lastfid = -1;
while($row = mysql_fetch_row($q))
{
  list ($fid, $length, $dkey, $md5, $hostip, $http_port, $devid) = $row;
  if ($fid == $lastfid) continue;
  $lastfid = $fid;
  if (strlen ($fid) < 10)
    $fid = sprintf("%010d", $fid);
  if ("$md5" == "" && $_REQUEST['quick'])
    {
      $md5 = "oooooooooooooooooooooooooooooooo";
    }
  if ("$md5" == "" || $_REQUEST['recompute_all_md5'])
    {
      $devpath = "http://" . $hostip . ":" . $http_port . "/dev" . $devid;
      $url = $devpath."/"
	.substr($fid,0,1)."/"
	.substr($fid,1,3)."/"
	.substr($fid,4,3)."/"
	.$fid.".fid";
      $md5 = md5_file($url);
      mysql_query("replace delayed into md5 (fid,md5) values ('$fid','$md5')");
    }
  echo "$md5 $dkey\n";
}
echo "-------------------------------- eof\n";

// arch-tag: 5175c8f5-fccd-11db-9207-0015f2b17887
?>

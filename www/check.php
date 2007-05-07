<?php

header("Content-type: text/plain");
ini_set("output_buffering",0);

require_once 'inc-mogilefs.php';

$q = mysql_query("select
     file.fid,
     file.length,
     file.dkey,
     concat('http://',hostip,':',http_port,'/dev',device.devid)
     from file
     left join file_on on file_on.fid=file.fid
     left join device on device.devid=file_on.devid
     left join host on host.hostid=device.hostid
     left outer join md5 on md5.fid=file.fid
     where md5 is null
     order by fid, rand()");
$lastfid = -1;
while($row = mysql_fetch_row($q))
{
  list ($fid, $length, $dkey, $devpath) = $row;
  if ($fid == $lastfid) continue;
  $lastfid = $fid;
  $fid = sprintf("%010d", $fid);
  $url = $devpath."/"
    .substr($fid,0,1)."/"
    .substr($fid,1,3)."/"
    .substr($fid,4,3)."/"
    .$fid.".fid";
  $md5 = md5_file($url);
  echo "$md5 $dkey $url $length\n";
  mysql_query("replace into md5 (fid,md5) values ('$fid','$md5')");
}

// arch-tag: bba641c3-fce6-11db-9207-0015f2b17887
?>

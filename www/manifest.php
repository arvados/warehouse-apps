<?php

header("Content-type: text/plain");
set_time_limit(120);

require_once 'inc-mogilefs.php';
$domain = defined($_REQUEST['domain'])? $_REQUEST['domain'] : $mogilefs_domain;
$class = defined($_REQUEST['class'])? $_REQUEST['class'] : $mogilefs_class;

$keyprefix = $_REQUEST['keyprefix'];
$q = mysql_query("select
     file.fid,
     file.length,
     file.dkey,
     md5,
     concat('http://',hostip,':',http_port,'/dev',device.devid)
     from file
     left join file_on on file_on.fid=file.fid
     left join device on device.devid=file_on.devid
     left join host on host.hostid=device.hostid
     left join domain on domain.dmid=file.dmid
     left join class on class.classid=file.classid
     left outer join md5 on md5.fid=file.fid
     where dkey like '$keyprefix%'
     and domain.namespace='$domain'
     and class.classname='$class'
     order by dkey, rand()");
echo mysql_error();
$lastfid = -1;
while($row = mysql_fetch_row($q))
{
  list ($fid, $length, $dkey, $md5, $devpath) = $row;
  if ($fid == $lastfid) continue;
  $lastfid = $fid;
  $fid = sprintf("%010d", $fid);
  if ("$md5" == "")
    {
      $url = $devpath."/"
	.substr($fid,0,1)."/"
	.substr($fid,1,3)."/"
	.substr($fid,4,3)."/"
	.$fid.".fid";
      $md5 = md5_file($url);
      mysql_query("replace into md5 (fid,md5) values ('$fid','$md5')");
    }
  echo "$md5 $dkey\n";
}

// arch-tag: 5175c8f5-fccd-11db-9207-0015f2b17887
?>

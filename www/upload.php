<?php

require_once 'inc-mogilefs.php';
$domain = $_REQUEST['domain'];
$class = $_REQUEST['class'];

for ($i=""; isset($_FILES["upload$i"]); $i=0+$i+1)
{
  $key = $_POST["key$i"];
  $tmpfile = $_FILES["upload$i"]['tmp_name'];
  exec ("echo $key $tmpfile >&2");
  exec ("./inject"
	." ".escapeshellarg($mogilefs_trackers)
	." ".escapeshellarg($domain)
	." ".escapeshellarg($class)
	." ".escapeshellarg($key)
	." ".escapeshellarg($tmpfile));
  include 'checkmd5.php';
  echo mogilefs_getmd5(mogilefs_getfid($key, $domain)) . "\n";
  unlink ($tmpfile);
}

// arch-tag: 74aa41a2-f9a2-11db-9207-0015f2b17887
?>

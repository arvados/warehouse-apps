<?php

require_once 'inc-mogilefs.php';
$domain = $_REQUEST['domain'];
$class = $_REQUEST['class'];

$key = $_POST['key'];
$tmpfile = $_FILES['upload']['tmp_name'];
exec ("./inject"
      ." ".escapeshellarg($mogilefs_trackers)
      ." ".escapeshellarg($domain)
      ." ".escapeshellarg($class)
      ." ".escapeshellarg($key)
      ." ".escapeshellarg($tmpfile));
include 'checkmd5.php';
unlink($tmpfile);

// arch-tag: 74aa41a2-f9a2-11db-9207-0015f2b17887
?>

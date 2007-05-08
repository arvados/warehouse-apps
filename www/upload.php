<?php

require_once 'inc-mogilefs.php';
$domain = isset($_REQUEST['domain'])? $_REQUEST['domain'] : "default";
$class = isset($_REQUEST['class'])? $_REQUEST['class'] : "default";

$key = $_POST['key'];
$tmpfile = $_FILES['upload']['tmp_name'];
exec ("./inject"
      ." ".escapeshellarg($mogilefs_trackers)
      ." ".escapeshellarg($domain)
      ." ".escapeshellarg($class)
      ." ".escapeshellarg($key)
      ." ".escapeshellarg($tmpfile));
exec ("php-cgi checkmd5.php"
      ." domain=".escapeshellarg($domain)
      ." key=".escapeshellarg($key));
unlink($tmpfile);

// arch-tag: 74aa41a2-f9a2-11db-9207-0015f2b17887
?>

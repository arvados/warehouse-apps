<?php

$key = $_REQUEST['key'];
$tmpfile = tempnam("/tmp", "mogextract.");
exec ("mogtool extract --overwrite ".escapeshellarg($key)." ".escapeshellarg($tmpfile)." || rm ".escapeshellarg($tmpfile));
if (file_exists($tmpfile))
{
  $md5 = md5(file_get_contents($tmpfile));
  unlink($tmpfile);
  echo "$md5";
}

// arch-tag: 420a7ce2-f9a4-11db-9207-0015f2b17887
?>

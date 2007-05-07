<?php

header("Content-type: text/plain");

$keyprefix = $_REQUEST['keyprefix'];
$tmpfile = tempnam("/tmp", "mogextract.");
exec ("mogtool listkey ".escapeshellarg($keyprefix), $keylist);
foreach ($keylist as $key)
{
  exec ("mogtool extract --overwrite ".escapeshellarg($key)." ".escapeshellarg($tmpfile)." || rm -f ".escapeshellarg($tmpfile));
  if (file_exists($tmpfile))
    {
      $md5 = md5(file_get_contents($tmpfile));
      unlink($tmpfile);
      echo "$md5 $key\n";
    }
}
// arch-tag: 5175c8f5-fccd-11db-9207-0015f2b17887
?>

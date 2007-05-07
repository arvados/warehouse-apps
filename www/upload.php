<?php

$md5 = md5(file_get_contents($_FILES['upload']['tmp_name']));
$key = $_POST['key'];
$tmpfile = tempnam("/tmp", "upload.");
if (move_uploaded_file ($_FILES['upload']['tmp_name'], $tmpfile))
{
  exec ("(mogtool inject ".escapeshellarg($tmpfile)." ".escapeshellarg($key)."; rm ".escapeshellarg($tmpfile).") </dev/null >/dev/null 2>/dev/null &");
  #unlink($tmpfile);
}
?>

<?php
// arch-tag: 74aa41a2-f9a2-11db-9207-0015f2b17887
?>

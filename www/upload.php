<?php

require_once 'inc-mogilefs.php';
$domain = defined($_REQUEST['domain'])? $_REQUEST['domain'] : $mogilefs_domain;
$class = defined($_REQUEST['class'])? $_REQUEST['class'] : $mogilefs_class;

$key = $_POST['key'];
$tmpfile = tempnam("/tmp", "upload.");
if (move_uploaded_file ($_FILES['upload']['tmp_name'], $tmpfile))
{
  exec ("(mogtool "
	."--domain=".escapeshellarg($domain)
	." --class=".escapeshellarg($class)
	." inject ".escapeshellarg($tmpfile)
	." ".escapeshellarg($key)
	."; rm -f ".escapeshellarg($tmpfile)
	.") </dev/null >/dev/null 2>/dev/null &");
}
?>

<?php
// arch-tag: 74aa41a2-f9a2-11db-9207-0015f2b17887
?>

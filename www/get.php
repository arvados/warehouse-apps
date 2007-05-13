<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

putenv("MOGILEFS_DOMAIN=".$_REQUEST[domain]);
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

if ($_REQUEST[domain] == 'reports')
{
  header("Content-type: text/plain");
}
else if ($_REQUEST[domain] == 'images')
{
  header("Content-type: image/tiff");
}
else
{
  exit;
}

$safekey = escapeshellarg($_REQUEST[dkey]);
echo file_get_contents(trim(`./moggetpaths $safekey`));

?>

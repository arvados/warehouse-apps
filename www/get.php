<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';

putenv("MOGILEFS_DOMAIN=".$_REQUEST[domain]);
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

$filename = ereg_replace ("/", "-", ereg_replace("^/", "", $_REQUEST[dkey]));
header("Content-Disposition: attachment; filename=\"$filename\"");
if ($_REQUEST[domain] == 'reports')
{
  header("Content-type: text/plain");
}
else if ($_REQUEST[domain] == 'images')
{
  if (ereg ("/(positions|cycles)$", $_REQUEST[dkey]))
    {
      header ("Content-type: text/plain");
    }
  else
    {
      header("Content-type: image/tiff");
    }
}
else
{
  exit;
}

$safekey = escapeshellarg($_REQUEST[dkey]);

echo_file_get_contents(trim(`perl moggetpaths.pl $safekey`));

?>

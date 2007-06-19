<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';

putenv("MOGILEFS_DOMAIN=".$_REQUEST[domain]);
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

unset($filter);

$filename = ereg_replace ("/", "-", ereg_replace("^/", "", $_REQUEST[dkey]));
if ($_REQUEST[domain] == 'reports')
{
  header("Content-Disposition: attachment; filename=\"$filename\"");
  header("Content-type: text/plain");
}
else if ($_REQUEST[domain] == 'images')
{
  if (ereg ("/(positions|cycles)$", $_REQUEST[dkey]))
    {
      header ("Content-type: text/plain");
    }
  else if ($_REQUEST[format] == 'png')
    {
      $filter = "convert tif:- png:-";
      header ("Content-type: image/png");
    }
  else
    {
      header("Content-Disposition: attachment; filename=\"$filename\"");
      header ("Content-type: image/tiff");
    }
}
else
{
  exit;
}

$safekey = escapeshellarg($_REQUEST[dkey]);

if ($filter)
{
  $url = escapeshellarg (trim (`perl moggetpaths.pl $safekey`));
  passthru ("wget -O - $url | $filter");
}
else
{
  echo_file_get_contents(trim(`perl moggetpaths.pl $safekey`));
}

?>

<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';

putenv("MOGILEFS_DOMAIN=".$_REQUEST[domain]);
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

unset($filter);

$dkey = $_REQUEST[dkey];
$filename = ereg_replace ("/", "-", ereg_replace("^/", "", $dkey));
if ($_REQUEST[domain] == 'reports')
{
  header("Content-Disposition: attachment; filename=\"$filename\"");
  header("Content-type: text/plain");
}
else if ($_REQUEST[domain] == 'images')
{
  if (ereg ("/(positions|cycles)$", $dkey) || $_REQUEST[format] == 'text')
    {
      header ("Content-Disposition: attachment; filename=\"$filename.txt\"");
      header ("Content-type: text/plain");
    }
  else if ($_REQUEST[format] == 'png')
    {
      $convert = "convert";
      $transform = "-normalize";
      if (ereg ("\.raw$", $dkey))
	{
	  $filter = "$convert -endian lsb -size 1000x1000 gray:- $transform png:-";
	}
      else if (ereg ("\.raw.gz$", $dkey))
	{
	  $filter = "zcat | $convert -endian lsb -size 1000x1000 gray:- $transform png:-";
	}
      else if (ereg ("\.tif$", $dkey))
	{
	  $filter = "$convert tif:- $transform png:-";
	}
      else if (ereg ("\.tif.gz$", $dkey))
	{
	  $filter = "zcat | $convert tif:- $transform png:-";
	}
      header ("Content-type: image/png");
    }
  else
    {
      header("Content-Disposition: attachment; filename=\"$filename\"");
      header ("Content-type: application/octet-stream");
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
  passthru ("wget -q -O - $url | $filter");
}
else
{
  echo_file_get_contents(trim(`perl moggetpaths.pl $safekey`));
}

?>

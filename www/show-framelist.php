<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

putenv("MOGILEFS_DOMAIN=images");
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

$dsid = $_REQUEST[dsid];

?>
<html>
<head><title><?=htmlspecialchars("report $rid detail")?></title></head>
<body>
<h1><a href="./"><?=htmlspecialchars(trim(`hostname`))?></a> / <?=$dsid?> images</h1>

<h2>frames</h2>

<?php

$positions = explode ("\n", file_get_contents (trim(`perl moggetpaths.pl /$dsid/IMAGES/RAW/positions`)));

$xy = array();
$nframes = 0;
foreach ($positions as $p)
{
  $p = ereg_replace ("[ \t]+", " ", $p);
  $p = explode (" ", $p);
  if (ereg ("^0*([0-9]+)$", $p[0], $regs))
    {
      $framexy[$regs[1]] = array ($p[1], $p[2]);
      if ($nframes < $regs[1])
	$nframes = $regs[1];
    }
}

for ($fid=1; $fid<$nframes; $fid++)
{
  echo "<a href=\"show-frame.php?dsid=$dsid&frame=$fid\">$fid</a>&nbsp; ";
}

?>

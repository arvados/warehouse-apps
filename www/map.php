<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

putenv("MOGILEFS_DOMAIN=images");
putenv("MOGILEFS_TRACKERS=".join(",", $mogilefs_trackers));

$rid = $_REQUEST[rid];
$dsid = mysql_one_value ("select dsid from report where rid='$rid'");

$positions = explode ("\n", file_get_contents (`./moggetpaths /$dsid/IMAGES/RAW/positions`));

$xy = array();
foreach ($positions as $p)
{
  $p = ereg_replace ("[ \t]+", " ", $p);
  $p = explode (" ", $p);
  if (ereg ("^0*([0-9]+)$", $p[0], $regs))
    {
      $framexy[$regs[1]] = array ($p[1], $p[2]);
    }
}

foreach ($framexy as $fid => $xy)
{
  list ($x, $y) = $xy;
  if (!isset($xmin))
    {
      $xmin = $xmax = $x;
      $ymin = $ymax = $y;
    }
  else
    {
      if ($xmin > $x) $xmin = $x;
      else if ($xmax < $x) $xmax = $x;
      if ($ymin > $y) $ymin = $y;
      else if ($ymax < $y) $ymax = $y;
    }
  $xall[] = $x;
}

$framesize = 10000;
foreach ($framexy as $f => $xy)
{
  foreach ($xall as $x)
    {
      if (25 < ($x - $xmin) && ($x - $xmin) < $framesize)
	{
	  $framesize = $x - $xmin;
	}
    }
}
$framesize = floor ($framesize * 9/10);

$xmax += $framesize;
$ymax += $framesize;

$xmin -= $framesize/2;
$ymin -= $framesize/2;
$xmax += $framesize/2;
$ymax += $framesize/2;

$w = 1024;
$h = floor ($w * ($ymax - $ymin) / ($xmax - $xmin));
$scale = $w / ($xmax - $xmin);
$legendh = 16;

$i = imagecreate ($w, $h + $legendh);
$bgcolor = imagecolorallocate ($i, 0xff, 0xff, 0xff);
$gridcolor = imagecolorallocate ($i, 0xaa, 0xaa, 0xaa);
$datacolor_light = imagecolorallocate ($i, 0xaa, 0xaa, 0xff);
$datacolor_dark = imagecolorallocate ($i, 0x77, 0x77, 0xff);
$legendcolor = imagecolorallocate ($i, 0, 0, 0);

$zmax = mysql_one_value ("select max(cast(substring(wc_stdout,1,locate(' ',wc_stdout)) as unsigned)) from job where rid='$rid'");
if ($zmax == 0) $zmax = 9999999;

$q = mysql_query ("select fid, wc_stdout from job where rid='$rid'");
while ($row = mysql_fetch_row ($q))
{
  list ($fid, $z) = $row;
  $fid = ereg_replace("^0+", "", $fid);
  $z = ereg_replace(" .*", "", $z);
  $x = $framexy[$fid+0][0];
  $y = $framexy[$fid+0][1];
  //  imagestring ($i, 3, 0, 10*$fid, "$fid $x $y $z $zmax", $gridcolor);

  $x -= $xmin;
  $y -= $ymin;
  $x2 = $x + $framesize;
  $y2 = $y + $framesize;
  $x *= $scale;
  $y *= $scale;
  $x2 *= $scale;
  $y2 *= $scale;

  //  imagestring ($i, 3, 512, 10*$fid, "$fid $x $y $x2 $y2 $z $zmax", $gridcolor);
  imagerectangle ($i, $x, $y, $x2, $y2, $gridcolor);
  $radius = ceil($framesize*$scale*sqrt($z/$zmax));
  if ($radius > 0)
    {
      imagefilledellipse ($i, ($x+$x2)/2, ($y+$y2)/2, $radius, $radius,
			  $datacolor_light);
      imageellipse ($i, ($x+$x2)/2, ($y+$y2)/2, $radius, $radius,
		    $datacolor_dark);
    }
}

imagestring ($i, 3, $framesize*$scale/2, $h+2, "max(z) = $zmax", $legendcolor);
imagerectangle ($i, 0, 0, $w-1, $h-1, $gridcolor);
header ("Content-type: image/png");
imagepng ($i);

?>

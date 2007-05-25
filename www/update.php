<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
set_time_limit(600);

mysql_connect($mogilefs_mysql_host,
	      $mogilefs_mysql_username,
	      $mogilefs_mysql_password);
echo mysql_error();

mysql_select_db($mogilefs_mysql_database);
echo mysql_error();

lock_or_exit("dataset");

putenv("MOGILEFS_TRACKERS=".join(",",$mogilefs_trackers));

function dbsetup()
{
  global $analysis_mysql_host,
    $analysis_mysql_username,
    $analysis_mysql_password,
    $analysis_mysql_database;
  mysql_connect($analysis_mysql_host,
		$analysis_mysql_username,
		$analysis_mysql_password);
  echo mysql_error();
  mysql_select_db($analysis_mysql_database);
  echo mysql_error();
  mysql_query("
create table
 if not exists
 dataset
(
 dsid char(32) not null primary key,
 nframes int,
 ncycles int
)");
  mysql_query("
create table
 if not exists
 cycle
(
 dsid char(32) not null,
 cid char(32) not null,
 nfiles int,
 nbytes bigint,
 exposure varchar(255),
 unique(dsid,cid)
)");
  echo mysql_error();
}

function grok ($fid=undef, $length=undef, $dmid=undef, $dkey=undef)
{
  global $grok;
  global $namespace;
  global $positions;
  global $cycles;
  if ($fid !== undef)
    {
      $dkey = explode("/", ereg_replace("^/*","",$dkey));
      $subdir = $dkey[count($dkey)-2];
      $dataset = $dkey[0];
      if (!isset($grok[$dataset]))
	{
	  $grok[$dataset] = array();
	}
      if (!isset($grok[$dataset][$subdir]))
	{
	  $grok[$dataset][$subdir] = array();
	  $grok[$dataset][$subdir][length] = 0;
	  $grok[$dataset][$subdir][count] = 0;
	}
      $grok[$dataset][$subdir][length] += $length;
      $grok[$dataset][$subdir][count] ++;
    }
  else
    {
      dbsetup();
      echo "Updating dataset and cycle tables.\n";
      mysql_query("lock tables dataset write, cycle write");
      mysql_query("delete from dataset");
      mysql_query("delete from cycle");
      foreach ($grok as $dataset => $d)
	{
	  putenv("MOGILEFS_DOMAIN=images");
	  $key = escapeshellarg("/".$dataset."/IMAGES/RAW/cycles");
	  $cycles = file_get_contents(`./moggetpaths $key`);
	  $key = escapeshellarg("/".$dataset."/IMAGES/RAW/positions");
	  $positions = file_get_contents(`./moggetpaths $key`);
	  $nframes = 0;
	  foreach (explode("\n", $positions) as $p)
	    {
	      if (ereg ("^[0-9]+[ \t]", $p))
		{
		  ++$nframes;
		}
	    }
	  $ncycles = 0;
	  $cycleinfo = array();
	  foreach (explode("\n", $cycles) as $c)
	    {
	      if ($c == "") continue;
	      $csv = explode(",", $c);
	      ++$ncycles;
	      mysql_query ("
		insert ignore into cycle
		(dsid, cid)
		values
		('$dataset', '$csv[1]')");
	      mysql_query ("
		update cycle
		set exposure='$c'
		where dsid='$dataset' and cid='$csv[1]'");
	    }
	  mysql_query ("
	    replace into dataset
	    (dsid, nframes, ncycles)
	    values
	    ('$dataset',
	     '$nframes',
	     '$ncycles')");
	  foreach ($d as $subdir => $s)
	    {
	      mysql_query("
		insert ignore into cycle
		(dsid, cid)
		values
		('$dataset', '$subdir')");
	      mysql_query("
		update cycle set
		nfiles='$s[count]',
		nbytes='$s[length]'
		where dsid='$dataset' and cid='$subdir'");
	    }
	}
      mysql_query("unlock tables");
      echo "Done.\n";
    }
}

$namespace = array();
$dmid_images = mysql_one_value("select dmid from domain where namespace='images'");

$q = mysql_query("select
     file.fid,
     file.length,
     file.dmid,
     file.dkey
     from file
     where dmid='$dmid_images'
     order by dmid,dkey");
echo mysql_error();
$lastfid = -1;
while($row = mysql_fetch_row($q))
{
  list ($fid, $length, $dmid, $dkey) = $row;
  if ($fid == $lastfid) continue;
  $lastfid = $fid;
  if (ereg("/IMAGES/RAW/positions$", $dkey)) continue;
  if (ereg("/IMAGES/RAW/cycles$", $dkey)) continue;
  grok($fid, $length, $dmid, $dkey);
}
grok();

// arch-tag: acc56792-0004-11dc-9207-0015f2b17887
?>

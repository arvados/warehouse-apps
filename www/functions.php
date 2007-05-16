<?php

function addcommas ($n)
{
  while (ereg("[0-9][0-9][0-9][0-9]", $n))
    {
      $n = ereg_replace ("([0-9]+)([0-9][0-9][0-9])", "\\1,\\2", $n);
    }
  return $n;
}

function mysql_one_assoc ($sql)
{
  $q = mysql_query ($sql);
  return mysql_fetch_assoc ($q);
}

function mysql_one_row ($sql)
{
  $q = mysql_query ($sql);
  return mysql_fetch_row ($q);
}

function mysql_one_value ($sql)
{
  $r = mysql_one_row ($sql);
  return $r[0];
}

function lock_or_exit ($lockname)
{
  global $lockfile_prefix;
  $lockfile = $lockfile_prefix.$lockname;
  $lockfp = fopen($lockfile, "w+");
  if (!flock($lockfp, LOCK_EX|LOCK_NB))
    {
      fclose($lockfp);
      echo "Someone else has lock on $lockfile so I quit.\n";
      exit;
    }
}

function echo_file_get_contents ($filename)
{
  if ($fh = fopen ($filename, "r"))
    {
      while (strlen($buf = fread ($fh, 8192)))
	{
	  echo $buf;
	}
      fclose ($fh);
    }
}

?>

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

?>

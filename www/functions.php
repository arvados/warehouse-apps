<?php

function addcommas ($n)
{
  while (ereg("[0-9][0-9][0-9][0-9]", $n))
    {
      $n = ereg_replace ("([0-9]+)([0-9][0-9][0-9])", "\\1,\\2", $n);
    }
  return $n;
}

?>
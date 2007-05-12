<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';

mysql_connect($analysis_mysql_host,
	      $analysis_mysql_username,
	      $analysis_mysql_password);
echo mysql_error();
mysql_select_db($analysis_mysql_database);
echo mysql_error();

echo "<table cellpadding=0 cellspacing=0 border=0>\n";
$q = mysql_query("select * from cycle order by dsid, cid");
while ($row = mysql_fetch_assoc ($q))
{
  echo "<tr><td>$row[dsid]</td><td>&nbsp;$row[cid]</td><td align=right>&nbsp;".addcommas($row[nfiles])."&nbsp;</td><td align=right>".addcommas($row[nbytes])."</td></tr>\n";
}
echo "</table>\n";

?>

<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

$dsid = $_REQUEST[dsid];

echo "<h1><a href=\"./\">".trim(`hostname`)."</a> / $dsid</h1>\n";

echo "<table border=0>\n";
echo "<tr>
  <td valign=bottom>cycle</td>
  <td valign=bottom>complete?</td>
  <td valign=bottom align=right>#files</td>
  <td valign=bottom align=right>#bytes</td>
  <td valign=bottom>exposure info from all_cycles.cfg</td>
</tr>
";

$totalbytes = 0;
$q = mysql_query("select *,
 if(nframes*4=nfiles,'Y','-') iscomplete
 from cycle
 left join dataset on cycle.dsid=dataset.dsid
 where cycle.dsid='$dsid'
 order by cid");
while ($cycle = mysql_fetch_assoc ($q))
{
  $exposure = $cycle[exposure];
  $exposure = ereg_replace("^[^,]*,[^,]*,", "", $exposure);
  echo "<tr><td>".$cycle[cid]."</td>"
    ."<td>".$cycle[iscomplete]."</td>"
    ."<td align=right>".addcommas($cycle[nfiles])."</td>"
    ."<td align=right>".addcommas($cycle[nbytes])."</td>"
    ."<td>".$exposure."</td>"
    ."</tr>\n";
  $totalbytes += $cycle[nbytes];
}
echo "<tr><td/><td/><td/><td>".addcommas($totalbytes)."</td></tr>\n";
echo "</table>\n";

?>

<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

$dsid = $_REQUEST[dsid];

?>
<html>
<head><title><?=htmlspecialchars($dsid)?></title></head>
<body>
<h1><a href="./"><?=htmlspecialchars(trim(`hostname`))?></a> / <?=htmlspecialchars($dsid)?></h1>

<form method=get action="jobform.php">
<input type=hidden name="dsid" value="<?=htmlspecialchars($dsid)?>">
Select cycles, then <input type=submit value="Continue">

<table border=0>
<tr>
  <td></td>
  <td valign=bottom>cycle</td>
  <td valign=bottom>complete?</td>
  <td valign=bottom align=right>#files</td>
  <td valign=bottom align=right>#bytes</td>
  <td valign=bottom colspan=14>exposure info from all_cycles.cfg</td>
</tr>

<?php
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
  $exposure = ereg_replace(",", "</td><td align=right>", $exposure);
  echo "<tr><td>";
  if ($cycle[iscomplete] == 'Y')
    {
      echo "<input type=checkbox name=\"cid[]\" value=\""
	.htmlspecialchars($cycle[cid])
	."\" checked>";
    }
  echo "</td><td>".$cycle[cid]."</td>"
    ."<td>".$cycle[iscomplete]."</td>"
    ."<td align=right>".addcommas($cycle[nfiles])."</td>"
    ."<td align=right>".addcommas($cycle[nbytes])."</td>"
    ."<td align=right>".$exposure."</td>"
    ."</tr>\n";
  $totalbytes += $cycle[nbytes];
}
echo "<tr><td/><td/><td/><td>".addcommas($totalbytes)."</td></tr>\n";
?>

</table>
</form>

</body>
</html>

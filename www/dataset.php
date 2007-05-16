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

<h2>reports</h2>

<table>
<tr>
 <td align=right>id</td>
 <td colspan=2></td>
 <td align=right>#jobs</td>
 <td>finished</td>
 <td>baseorder/knobs</td>
</tr>
<?php
$q = mysql_query("select
 report.*,
 count(jid) njobs,
 date_format(max(job.finished),'%Y-%m-%d %H:%i') last_finished,
 max(job.finished is null) unfinished
 from report
 left outer join job on report.rid=job.rid
 where dsid='$dsid'
 group by report.rid
 order by last_finished desc");
echo mysql_error();
while ($row = mysql_fetch_assoc ($q))
{
  echo "<tr>";
  echo "<td valign=top align=right>$row[rid]</td>";
  echo "<td valign=top><a href=\"map.php?rid=$row[rid]\">map</a></td>";
  echo "<td valign=top><a href=\"jobstatus.php?rid=$row[rid]\">detail</a></td>";
  echo "<td valign=top align=right>$row[njobs]</td>";
  if ($row[unfinished])
    echo "<td valign=top><b>".mysql_one_value("select count(*) from job where rid='$row[rid]' and finished is not null")."</b></td>";
  else
    echo "<td valign=top>$row[last_finished]</td>";
  echo "<td valign=top><code>".nl2br(htmlspecialchars(ereg_replace(","," ",$row[baseorder])."\n".$row[knobs]))."</code></td>";
  echo "</tr>\n";
}
?>
</table>

<h2>new job</h2>

<form method=get action="jobform.php">
<input type=hidden name="dsid" value="<?=htmlspecialchars($dsid)?>">
To submit a job, select cycles, then press <input type=submit value="Next"> to set knobs.

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

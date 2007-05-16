<?php

require_once '/etc/polony-tools/config.php';
$source = escapeshellarg($svn_repos);

$nnodes = 0;
foreach(explode("\n", `sinfo --noheader --format=%D`) as $n)
{
  $nnodes += $n;
}

if ($_POST[revision] > 0)
{
  $revision = 0 + $_POST[revision];

  $pwd = escapeshellarg(trim(`pwd`));
  `srun --overcommit -N$nnodes --chdir=/tmp --output=/usr/local/polony-tools/$revision.batch-log --batch $pwd/installrevision.sh $revision $source 2>&1`;

  sleep(1);
  header("Location: installrevision.php");
  exit;
}

?>
<html>
<head><title>polony-tools revisions</title>
</head>
<body>

<?php
$fetched = array();
$listall = `srun --immediate --share --overcommit -N$nnodes --chdir=/tmp sh -c 'ls -d1 /usr/local/polony-tools/*/. /usr/local/polony-tools/*/.tested /usr/local/polony-tools/*/.fetched'`;
foreach (explode ("\n", $listall) as $rev)
{
  if (ereg("/([0-9]+)/\.$", $rev, $regs))
    {
      $started[$regs[1]]++;
    }
  if (ereg("/([0-9]+)/\.fetched$", $rev, $regs))
    {
      $fetched[$regs[1]]++;
    }
  if (ereg("/([0-9]+)/\.tested$", $rev, $regs))
    {
      $tested[$regs[1]]++;
    }
}
?>

<table>
<tr>
 <td valign=bottom>revision</td>
 <td>tested/<br>fetched/<br>started</td>
 <td></td>
 <td valign=bottom colspan=3>commit log</td>
</tr>
<?php
$log = `svn log $source`;
foreach (explode("------------------------------------------------------------------------\n", $log) as $logentry)
{
  if (ereg ("^r([0-9]+)", $logentry, $regs))
    {
      $revision = $regs[1];
      $ready = ($tested[$revision] == $nnodes) ? "<b>$revision</b>" : $revision;

      list ($line1, $msg) = explode ("\n\n", $logentry, 2);
      list ($x, $committer, $date, $x) = explode (" | ", $line1);
      $date = ereg_replace (" [-+].*", "", $date);
      $htmlspecialdate = ereg_replace (" ", "&nbsp;", htmlspecialchars($date));

      echo "<tr>";
      echo "<td valign=top>$ready</td>";
      echo "<td valign=top>"
	.($tested[$revision]+0)
	."/"
	.($fetched[$revision]+0)
	."/"
	.($started[$revision]+0)
	."</td>";

      echo "<td valign=top>";
      if ($tested[$revision] < $nnodes)
	{
	  if ($fetched[$revision])
	    {
	      $action = "Restart";
	    }
	  else
	    {
	      $action = "Install";
	    }
	  echo "<form method=post><input type=submit value=\"$action\"><input type=hidden name=revision value=\"$revision\"></form>";
	}
      echo "</td>";

      echo "<td valign=top>".htmlspecialchars($committer)."</td>";
      echo "<td valign=top>$htmlspecialdate</td>";
      echo "<td valign=top>".htmlspecialchars($msg)."</td>";
      echo "</tr>\n";
    }
}
?>
</table>
</body>
</html>

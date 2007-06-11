<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

$dsid = $_POST[dsid];
$revision = $_POST[revision] + 0;
$source = escapeshellarg($svn_repos);

if (!($revision > 0))
{
  if (ereg ("\nRevision: ([0-9]+)\n", `svn info $svn_repos`, $regs))
    {
      $revision = $regs[1];
    }
}

$nframes = mysql_one_value ("select nframes from dataset where dsid='$dsid'");

echo "<p>Job will run on $nframes frames.\n";
for($i=0; $i<1024; $i++) { echo "    "; } echo "\n";
flush();

mysql_query("insert into report set
 dsid='".addslashes($dsid)."',
 revision='$revision',
 baseorder='".addslashes(join(",",$_POST[cid]))."',
 knobs='".addslashes($_POST[knobs])."'");
$rid = mysql_insert_id();
if(!$rid)
{
  echo "Error inserting new row in report table: ".mysql_error();
  exit;
}

$depends = "";
$pwd = escapeshellarg(trim(`pwd`));
$nnodes = 0;
foreach(explode("\n", `sinfo --noheader --format=%D`) as $n)
{
  $nnodes += $n;
}
$srunout = `srun --job-name='r$revision' --overcommit -N$nnodes --chdir=/tmp --output=none --batch $pwd/installrevision.sh $revision $source 2>&1`;
if (ereg ("jobid ([0-9]+) submitted", $srunout, $regs))
{
  $depends = "--dependency=$regs[1]";
}
echo "<p>Submitted install job $regs[1].\n";

$revisiondir = "/usr/local/polony-tools/$revision";

for ($f=1; $f<=$nframes; $f++)
{
  $fid = sprintf ("%04d", $f);
  $dkey_stdout="/$rid/frame/$fid";
  $dkey_stderr="/$rid/frame/$fid.stderr";
  $jobname = escapeshellarg("$rid:$fid:$dsid");
  $cmd = "srun --job-name=$jobname $depends --batch --chdir=$revisiondir --output=/tmp/stdout --error=/tmp/stderr ./onejob.sh";
  mysql_query ("insert into job set
 jid=null,
 rid='$rid',
 fid='$fid',
 dkey_stdout='$dkey_stdout',
 dkey_stderr='$dkey_stderr',
 cmd='".addslashes($cmd)."'");
}

?>

<p>Queued <?=$nframes?> jobs for submission to slurm.
<p>You may proceed to the
<a href="jobstatus.php?rid=<?=$rid?>">job <?=$rid?> status</a>
page.

</body>
</html>

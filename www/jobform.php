<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

$dsid = $_REQUEST[dsid];

?>
<html>
<head><title><?=htmlspecialchars($dsid)?> job knobs</title></head>
<body>
<h1><a href="./"><?=htmlspecialchars(trim(`hostname`))?></a> / job knobs for <?=htmlspecialchars($dsid)?> job</h1>

<form method=post action="jobsubmit.php">
<table>

<tr>
 <td valign=top>Dataset</td>
 <td valign=top><?=htmlspecialchars($dsid)?></td>
</tr>
<input type=hidden name="dsid" value="<?=htmlspecialchars($dsid)?>">

<tr>
 <td valign=top>Cycles</td>
 <td valign=top><?=nl2br(htmlspecialchars(join("\n",$_REQUEST[cid])))?></td>
</tr>
<input type=hidden name="cid[]" value="<?=join("\">\n<input type=hidden name=\"cid[]\" value=\"", $_REQUEST[cid])?>">

<tr>
 <td></td>
 <td><input type=submit value="Start">
</tr>

</table>
</form>

</body>
</html>

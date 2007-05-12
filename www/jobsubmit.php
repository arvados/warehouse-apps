<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

$dsid = $_REQUEST[dsid];
$cid = $_REQUEST[cid];

header("Location: ./dataset.php?dsid=".urlencode($dsid));
exit;
?>

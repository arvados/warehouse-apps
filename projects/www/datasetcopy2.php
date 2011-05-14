<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

$dsid = escapeshellarg($_POST[dsid]);
$remotelims = escapeshellarg($_POST[remotelims]);

`touch /tmp/dscopy:$dsid:$remotelims`;

header("Location: ./datasetcopy.php");


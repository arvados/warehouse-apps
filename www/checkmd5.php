<?php

require_once 'inc-mogilefs.php';

echo mogilefs_getmd5(mogilefs_getfid($_REQUEST['key'],
				     $_REQUEST['domain'],
				     $_REQUEST['class'])) . "\n";

// arch-tag: 420a7ce2-f9a4-11db-9207-0015f2b17887
?>

<?php

mysql_connect($analysis_mysql_host,
	      $analysis_mysql_username,
	      $analysis_mysql_password);
echo mysql_error();
mysql_select_db($analysis_mysql_database);
echo mysql_error();

?>
<?php

require_once '/etc/polony-tools/config.php';
require_once 'functions.php';
require_once 'connect.php';

mysql_query("create table if not exists report
(
 rid bigint not null auto_increment primary key,
 dsid char(32),
 revision int,
 baseorder varchar(255),
 knobs text,
 index(dsid)
) engine=innodb");
echo mysql_error();

mysql_query("create table if not exists job
(
 jid bigint not null auto_increment primary key,
 sjid bigint,
 rid bigint references report.rid,
 fid char(4),
 dkey_stdout char(32),
 dkey_stderr char(32),
 wc_stdout char(32),
 wc_stderr char(32),
 cmd text,
 submittime datetime,
 finished datetime,
 attempts int default 0,
 index(rid),
 index(finished)
) engine=innodb");
echo mysql_error();

mysql_query("create table if not exists dataset
(
 dsid char(32) not null primary key,
 nframes int,
 ncycles int
) engine=innodb");
echo mysql_error();

mysql_query("create table if not exists cycle
(
 dsid char(32) not null,
 cid char(32) not null,
 nfiles int,
 nbytes bigint,
 exposure varchar(255),
 unique(dsid,cid)
) engine=innodb");
echo mysql_error();

?>
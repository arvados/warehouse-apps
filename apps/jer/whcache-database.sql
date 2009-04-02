use whcache;

-- WharehouseCache

create table whjobstat (
	id int not null, primary key(id),
	starttime bigint,
	finishtime bigint,
	nodes smallint,
	bottom smallint,
	mrfunction varchar(24)
 );

-- WarehouseTools::Cache

create table resultsets (
	id int not null auto_increment, primary key(id),
	handle char(32) not null unique,
	request_fetch enum('Y','N') default 'Y',
	jobs_count int,
	jobs_time int,
	output_count int,
	output_size bigint,	
	last_fetch datetime
);

create table manifests (
	id int not null auto_increment, primary key(id),
	hash char(32) not null unique,
	jobs_count int,
	jobs_time int,
	output_count int,
	output_size bigint,
	sanity enum('N','Y'),
	gcsafe enum('N','Y'),
	request_fetch enum('Y','N') default 'Y',
	last_fetch datetime,
	last_gcsafe datetime
);

create table datasets (
	id int not null auto_increment, primary key(id),
	hash char(32) not null unique,
	size bigint,
	sanity enum('N','Y'),
	gcsafe enum('N','Y'),
	request_fetch enum('Y','N') default 'Y',
	last_fetch datetime,
	last_gcsafe datetime
);

create table resultsetrefs (
	id int not null auto_increment, primary key(id),
	resultset int not null,
	manifest int not null
);

create table datasetrefs (
	id int not null auto_increment, primary key(id),
	dataset int not null,
	manifest int not null
);

create table recoverjob (
	id int not null auto_increment, primary key(id),
	query varchar(32) not null unique,
	last_fetch datetime,
	request_fetch enum('Y','N') default 'Y',
	intact enum('Y','N'),
	solution varchar(33000)
);


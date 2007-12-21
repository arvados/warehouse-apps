do '/etc/regol.conf' or do
{
    print CGI->header (-status=>500);
    print "500 no config file in /etc/regol.conf";
    exit 1;
};

$main::dbh = DBI->connect(@$main::DatabaseDSN) or do
{
    print CGI->header (-status=>500);
    print "500 could not connect to database: ".DBI->errstr;
    exit 1;
};

$SIG{__DIE__} = sub
{
    print CGI->header (-status=>500);
    print "500 @_";
    exit 1;
};

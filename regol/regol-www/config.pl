do '/etc/regol.conf' or do
{
    print CGI->header (-status=>500);
    print "500 no config file in /etc/regol.conf";
    exit 1;
};

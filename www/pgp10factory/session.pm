package session;

use CGI::Cookie;

mkdir "session";
(-d "session" && -w "session") or die "session dir cannot be created/written";

my $sessionid;
my @_togo;

sub init
{
    my ($q) = @_;
    my %cookies = fetch CGI::Cookie;
    if ($cookies{'session'}->value =~ /^[0-9a-f]{16}$/ && -d "session/$&")
    {
	$sessionid = $&;
	@_togo = (new CGI::Cookie (-name => 'session',
				   -value => $sessionid,
				   -expires => "+10y"));
    }
    else
    {
	open F, "<", "/dev/urandom";
	read F, $sessionid, 8;
	close F;
	$sessionid = unpack("h*", $sessionid);
	mkdir "session/$sessionid";
	@_togo = (new CGI::Cookie (-name => 'session',
				   -value => $sessionid,
				   -expires => "+10y"));
    }
}

sub hashes
{
}

sub togo
{
    return @_togo;
}

sub id
{
    return $sessionid;
}

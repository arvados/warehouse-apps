package Warehouse::HTTP;

BEGIN {
    eval {
	if (`which curl 2>/dev/null` =~ m{/curl}) {
	    $Warehouse::HTTP::useCurlCmd = 1;
	}
    };
    # libghttp seems to be the fastest perl http library.
    # Unfortunately, 'eval "use HTTP::GHTTP"' crashes perl if you
    # install libhttp-ghttp-perl on an ubuntu system and then upgrade
    # past ~maverick without removing it. "/usr/bin/perl: symbol
    # lookup error: /usr/lib/perl5/auto/HTTP/GHTTP/GHTTP.so: undefined
    # symbol: Perl_Tstack_sp_ptr"
    local $ENV{PATH} = '/bin:/usr/bin'; # avoids "insecure $ENV{PATH} while running with -T" (or setuid)
    if (`perl -e 'use HTTP::GHTTP; print "ok"' 2>/dev/null` eq 'ok') {
	eval "use HTTP::GHTTP; \$Warehouse::HTTP::useGHTTP = 1;";
    } else {
	$@ = 1;
    }
    if ($@) {
	eval "use LW2; \$Warehouse::HTTP::useLW2 = 1;";
    }
    if ($@) {
	eval "use WWW::Curl::Easy; \$Warehouse::HTTP::useCurl = 1;";
    }
    if ($@) {
	eval "use LWP::UserAgent; \$Warehouse::HTTP::useLWP = 1;";
    }
    if ($@) {
	die "could not find a supported HTTP library";
    }
}

sub new
{
    my $class = shift;
    if ($Warehouse::HTTP::useCurl) { return new Warehouse::HTTP::Curl (@_); }
    if ($Warehouse::HTTP::useGHTTP) { return new Warehouse::HTTP::GHTTP (@_); }
    if ($Warehouse::HTTP::useLW2) { return new Warehouse::HTTP::LW2 (@_); }
    if ($Warehouse::HTTP::useLWP) { return new Warehouse::HTTP::LWP (@_); }
    die "could not find a supported HTTP library";
}

sub set_method
{
    my $self = shift;
    $self->{method} = shift;
}

sub get_headers
{
    ""
}


package Warehouse::HTTP::Curl;

@ISA = qw(Warehouse::HTTP);

sub new
{
    my $class = shift;
    my $self = {};
    bless ($self, $class);
    return $self->_init();
}

sub _init
{
    my $self = shift;
    return $self;
}

sub set_uri
{
    my $self = shift;
    $self->{uri} = shift;
}

sub process_request
{
    my $self = shift;
    $self->{curl} = WWW::Curl::Easy->new;
    $self->{curl}->setopt(WWW::Curl::Easy::CURLOPT_HEADER, 0);
    $self->{curl}->setopt(WWW::Curl::Easy::CURLOPT_HEADERFUNCTION, \&writecb);
    $self->{curl}->setopt(WWW::Curl::Easy::CURLOPT_FAILONERROR, 1);
    $self->{curl}->setopt(WWW::Curl::Easy::CURLOPT_URL, $self->{uri});
    my $data = "";
    open (my $fh, ">", \$data);
    $self->{dataref} = \$data;
    $self->{curl}->setopt(WWW::Curl::Easy::CURLOPT_WRITEDATA, $fh);
    $self->{curl}->setopt(WWW::Curl::Easy::CURLOPT_FILE, $fh);
    $self->{retcode} = $self->{curl}->perform;
}

sub writecb
{
    return length ($_[0]);
}

sub get_status
{
    my $self = shift;
    if ($self->{retcode} == 0) { return (200, "OK"); }
    return ($self->{retcode}, $self->{curl}->strerror($self->{retcode})." ".$self->{curl}->errbuf);
}

sub get_body
{
    my $self = shift;
    return ${$self->{dataref}};
}



package Warehouse::HTTP::LW2;

@ISA = qw(Warehouse::HTTP);

sub new
{
    my $class = shift;
    my $self = {};
    bless ($self, $class);
    return $self->_init();
}

sub _init
{
    my $self = shift;
    return $self;
}

sub set_uri
{
    my $self = shift;
    $self->{uri} = shift;
}

sub process_request
{
    my $self = shift;
    $self->{request} = LW2::http_new_request();
    $self->{response} = LW2::http_new_response();
    LW2::uri_split ($self->{uri}, $self->{request});
    LW2::http_do_request ($self->{request}, $self->{response});
    ($self->{code}, $self->{data}) = ($self->{response}->{whisker}->{code},
				      $self->{response}->{whisker}->{data});
}

sub get_status
{
    my $self = shift;
    if ($self->{code} eq 200) { return ($self->{code}, "OK"); }
    return ($self->{code}, $self->{data});
}

sub get_body
{
    my $self = shift;
    return $self->{data};
}


package Warehouse::HTTP::LWP;

@ISA = qw(Warehouse::HTTP);

sub new
{
    my $class = shift;
    my $self = {};
    bless ($self, $class);
    return $self->_init();
}

sub _init
{
    my $self = shift;
    $self->{ua} = new LWP::UserAgent;
    $self->{ua}->agent ("libwarehouse-perl/".$Warehouse::VERSION);
    return $self;
}

sub set_uri
{
    my $self = shift;
    $self->{uri} = shift;
}

sub process_request
{
    my $self = shift;
    if ($self->{method} eq 'HEAD') {
	$self->{req} = new HTTP::Request (HEAD => $self->{uri});
    } else {
	$self->{req} = new HTTP::Request (GET => $self->{uri});
    }
    $self->{res} = $self->{ua}->request ($self->{req});
}

sub get_status
{
    my $self = shift;
    return ($self->{res}->code(),
	    $self->{res}->message());
}

sub get_body
{
    my $self = shift;
    return $self->{res}->content;
}


package Warehouse::HTTP::GHTTP;

@ISA = qw(Warehouse::HTTP);

sub new
{
    my $class = shift;
    my $self = {};
    bless ($self, $class);
    return $self->_init(@_);
}

sub _init
{
    my $self = shift;
    $self->{ghttp} = new HTTP::GHTTP(@_);
    return $self;
}

sub set_uri
{
    my $self = shift;
    return $self->{ghttp}->set_uri(@_);
}

sub process_request
{
    my $self = shift;
    return $self->{ghttp}->process_request(@_);
}

sub get_status
{
    my $self = shift;
    return $self->{ghttp}->get_status(@_);
}

sub get_body
{
    my $self = shift;
    return $self->{ghttp}->get_body(@_);
}

sub set_method
{
    my $self = shift;
    my $method = shift;
    $self->{ghttp}->set_type(HTTP::GHTTP::METHOD_HEAD) if $method eq 'HEAD';
}

sub get_headers
{
    my $self = shift;
    return join ("\n", map { "$_: " . $self->{ghttp}->get_header($_) } $self->{ghttp}->get_headers);
}


1;

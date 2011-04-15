package Warehouse::HTTP;

BEGIN {
    eval "use WWW::Curl::Easy; \$Warehouse::HTTP::useCurl = 1;";
    if ($@) {
	eval "use HTTP::GHTTP; \$Warehouse::HTTP::useGHTTP = 1;";
    }
    if ($@) {
	eval "use LW2; \$Warehouse::HTTP::useLW2 = 1;";
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
    if ($Warehouse::HTTP::useGHTTP) { return new HTTP::GHTTP (@_); }
    if ($Warehouse::HTTP::useLW2) { return new Warehouse::HTTP::LW2 (@_); }
    if ($Warehouse::HTTP::useLWP) { return new Warehouse::HTTP::LWP (@_); }
    die "could not find a supported HTTP library";
}

package Warehouse::HTTP::Curl;

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
    use WWW::Curl::Easy;
    my $self = shift;
    $self->{curl} = WWW::Curl::Easy->new;
    $self->{curl}->setopt(CURLOPT_HEADER, 0);
    $self->{curl}->setopt(CURLOPT_FAILONERROR, 1);
    $self->{curl}->setopt(CURLOPT_URL, $self->{uri});
    my $data = "";
    open (my $fh, ">", \$data);
    $self->{dataref} = \$data;
    $self->{curl}->setopt(CURLOPT_WRITEDATA, $fh);
    $self->{retcode} = $self->{curl}->perform;
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
    $self->{req} = new HTTP::Request (GET => $self->{uri});
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


1;

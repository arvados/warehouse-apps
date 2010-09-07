package Warehouse::HTTP;

BEGIN {
    eval "use HTTP::GHTTP; \$Warehouse::HTTP::useGHTTP = 1;";
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
    if ($Warehouse::HTTP::useGHTTP) { return new HTTP::GHTTP (@_); }
    if ($Warehouse::HTTP::useLW2) { return new Warehouse::HTTP::LW2 (@_); }
    if ($Warehouse::HTTP::useLWP) { return new Warehouse::HTTP::LWP (@_); }
    die "could not find a supported HTTP library";
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
    $self->{lw2} = new LW2;
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
    ($self->{code}, $self->{data}) = $self->{lw2}->get_page($self->{uri});
}

sub get_status
{
    my $self = shift;
    if ($self->{code} eq 200) { return ($self->{code}, "OK"); }
    return ($self->{code}, $self->{data});
}

sub get_body
{
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

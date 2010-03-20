sub cs2a
{
    my $tr = '0123103223013210';
    my $x = shift;
    $x =~ tr/ACGTacgt/0123/;
    my $ret = "";
    my $base = "";
    foreach (split "", $x) {
	if ($base eq "") { $base = $_; }
	else {
	    $base = substr $tr, $base * 4 + $_, 1;
	    $ret .= $base;
	}
    }
    $ret =~ tr/0123/ACGT/;
    return $ret;
}

1;

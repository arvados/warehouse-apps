package Safeget;
use Fcntl ':flock';
use Digest::MD5 'md5_hex';

sub wh_manifest_tree
{
    my ($data_locator, $local_dir) = @_;
    $local_dir
	or die "no local_dir specified";
    (open (L, "+>>", "$local_dir.lock") && flock (L, LOCK_EX))
	or die "Failed to lock $local_dir.lock";
    if (-d $local_dir &&
	-e "$local_dir/.locator.".md5_hex($data_locator)) {
	close L;
	return 1;
    }
    system ('rm', '-rf', "$local_dir.tmp") == 0
	or die "rm $local_dir.tmp failed: $?";
    mkdir "$local_dir.tmp"
	or die "mkdir $local_dir.tmp failed: $!";
    if (0 != system "whget -r '$data_locator'/ '$local_dir.tmp'/")
    {
	system "rm -rf '$local_dir.tmp'";
	die "whget exited $?";
    }
    symlink ".", "$local_dir.tmp/.locator.".md5_hex($data_locator);
    rename "$local_dir.tmp", "$local_dir"
	or die "rename $local_dir.tmp -> $local_dir failed: $!";
    close L;
    return 1;
}

sub wh_tarball_extract
{
    my ($data_locator, $local_dir) = @_;
    $local_dir
	or die "no local_dir specified";
    (open (L, "+>>", "$local_dir.lock") && flock (L, LOCK_EX))
	or die "Failed to lock $local_dir.lock";
    if (-d $local_dir &&
	-e "$local_dir/.locator.".md5_hex($data_locator)) {
	close L;
	return 1;
    }
    system ('rm', '-rf', "$local_dir.tmp") == 0
	or die "rm $local_dir.tmp failed: $?";
    mkdir "$local_dir.tmp"
	or die "mkdir $local_dir.tmp failed: $!";
    if (0 != system "whget '$data_locator' - | tar -C '$local_dir.tmp' -xzf -")
    {
	system "rm -rf '$local_dir.tmp'";
	die "whget exited $?";
    }
    symlink ".", "$local_dir.tmp/.locator.".md5_hex($data_locator);
    rename "$local_dir.tmp", "$local_dir"
	or die "rename $local_dir.tmp -> $local_dir failed: $!";
    close L;
    return 1;
}

sub wh_file
{
    my ($data_locator, $local_file) = @_;
    $local_file
	or die "no local_file specified";
    unless (open (L, "+>>", "$local_file.lock") &&
	    flock (L, LOCK_EX))
    {
	die "Failed to lock $local_file.lock";
    }
    if (readlink ("$local_file.locator") eq md5_hex($data_locator) &&
	-e $local_file) {
	close L;
	return 1;
    }
    my $sysret;
    if ($data_locator =~ /\.gz$/ && $local_file !~ /\.gz$/) {
	$sysret = system "whget '$data_locator' - | gzip -cd > '$local_file.tmp'";
    }
    else {
	$sysret = system "whget '$data_locator' '$local_file.tmp'";
    }
    if (0 != $sysret)
    {
	unlink "$local_file.tmp";
	close L;
	die "whget exited $?";
    }
    rename "$local_file.tmp", $local_file
	or die "rename $local_file.tmp failed: $!";
    symlink md5_hex($data_locator), "$local_file.locator";
    close L;
    return 1;
}

sub wh_stream_segment
{
    my ($stream, $pos, $size, $local_file) = @_;
    $local_file
	or die "no local_file specified";

    my $id = md5_hex($stream->as_string . " $pos $size");

    unless (open (L, "+>>", "$local_file.lock") &&
	    flock (L, LOCK_EX) )
    {
	die "Failed to lock $local_file.lock";
    }

    if (readlink ("$local_file.locator") eq $id &&
	-e $local_file) {
	close L;
	return 1;
    }
    open F, ">", "$local_file.tmp" or die "open $local_file.tmp: $!";
    $stream->seek($pos);
    while (my $dataref = $stream->read_until ($pos + $size)) {
	print F $$dataref or die "write $local_file.tmp: $!";
    }
    close F or die "close $local_file.tmp: $!";
    rename "$local_file.tmp", $local_file
	or die "rename $local_file.tmp failed: $!";
    symlink $id, "$local_file.locator";
    close L;
    return 1;
}

sub git {
    my ($git_url, $local_dir, $checkout_tag) = @_;
    $local_dir
	or die "no local_dir specified";

    my $commit = $checkout_tag;
    if ($commit !~ /^[0-9a-f]{5,40}$/) {
	$commit = `git ls-remote '$git_url' '$checkout_tag' | head -c40`;
	die "Failed to find commit-ish $checkout_tag at $git_url"
	    unless $commit =~ /^[0-9a-f]{40}$/;
    }

    my $sourcetag = md5_hex($git_url.$;.$commit);
    my ($local_dir_basename) = $local_dir =~ /([^\/]+)$/;
    return 1 if (readlink ($local_dir) eq "$local_dir_basename.$sourcetag" &&
		 -d $local_dir);
    if (open (L, "+>>", "$local_dir.lock") &&
	flock (L, LOCK_EX) )
    {
	system ("rm", "-rf", "$local_dir.$sourcetag");
	system ('git', 'clone', $git_url, "$local_dir.$sourcetag") == 0
	    or die "git clone $git_url failed: $?";
	my @cmds = ("git checkout --quiet '$commit'",
		    "[ ! -e .gitmodules ] || ( git submodule -q init && git submodule -q sync && git submodule -q update --init --recursive )");
	for (@cmds) {
	    unless (system ("cd '$local_dir.$sourcetag' && ( $_ )") == 0) {
		system ("rm", "-rf", "$local_dir.$sourcetag");
		die "$_ failed: $?";
	    }
	}
	unlink "$local_dir.tmp";
	symlink "$local_dir_basename.$sourcetag", "$local_dir.tmp"
	    or die "symlink $local_dir.tmp -> $local_dir_basename.$sourcetag failed: $!";
	rename "$local_dir.tmp", $local_dir
	    or die "rename $local_dir.tmp -> $local_dir failed: $!";
    }
    close L;
    die "Failed to clone $git_url -> $local_dir" if !-d $local_dir;
    return 1;
}

1;

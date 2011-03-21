package Safeget;
use Fcntl ':flock';
use Digest::MD5 'md5_hex';

sub wh_tarball_extract
{
    my ($data_locator, $local_dir) = @_;
    $local_dir
	or die "no local_dir specified";
    return 1 if -d $local_dir && -e "$local_dir/.locator.".md5_hex($data_locator);
    if (open (L, "+>>", "$local_dir.lock") &&
	flock (L, LOCK_EX) )
    {
	system ('rm', '-rf', "$local_dir.tmp") == 0
	    or die "rm $local_dir.tmp failed: $?";
	mkdir "$local_dir.tmp"
	    or die "mkdir $local_dir.tmp failed: $!";
	if (0 != system "whget '$data_locator' - | tar -C '$local_dir.tmp' -xzf -")
	{
	    system "rm -rf '$local_dir.tmp'";
	    close L;
	    die "whget exited $?";
	}
	symlink ".", "$local_dir.tmp/.locator.".md5_hex($data_locator);
	rename "$local_dir.tmp", "$local_dir"
	    or die "rename $local_dir.tmp -> $local_dir failed: $!";
    }
    close L;
    die "Failed to whget $data_locator -> $local_dir" if !-d $local_dir;
    return 1;
}

sub wh_file
{
    my ($data_locator, $local_file) = @_;
    $local_file
	or die "no local_file specified";
    return 1 if (readlink ("$local_file.locator") eq md5_hex($data_locator) &&
		 -e $local_file);
    if (open (L, "+>>", "$local_file.lock") &&
	flock (L, LOCK_EX) )
    {
	if (0 != system "whget '$data_locator' '$local_file.tmp'")
	{
	    unlink "$local_file.tmp";
	    close L;
	    die "whget exited $?";
	}
	symlink md5_hex($data_locator), "$local_file.locator";
	rename "$local_file.tmp", $local_file
	    or die "rename $local_file.tmp failed: $!";
    }
    close L;
    die "Failed to whget $data_locator -> $local_file" if !-e $local_file;
    return 1;
}

sub git {
    my ($git_url, $local_dir, $checkout_tag) = @_;
    $local_dir
	or die "no local_dir specified";
    my $sourcetag = md5_hex($git_url.$;.$checkout_tag);
    my ($local_dir_basename) = $local_dir =~ /([^\/]+)$/;
    return 1 if (readlink ($local_dir) eq "$local_dir_basename.$sourcetag" &&
		 -d $local_dir);
    if (open (L, "+>>", "$local_dir.lock") &&
	flock (L, LOCK_EX) )
    {
	system ("rm", "-rf", "$local_dir.$sourcetag");
	system ('git', 'clone', $git_url, "$local_dir.$sourcetag") == 0
	    or die "git clone $git_url failed: $?";
	system ("cd '$local_dir.$sourcetag' && git checkout --quiet '$checkout_tag'") == 0
	    or do {
		system ("rm", "-rf", "$local_dir.$sourcetag");
		die "git checkout --quiet $checkout_tag failed: $?";
	};
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

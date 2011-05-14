sub mr_get_mrfunction_params
{
  my ($mrfunction, $rev) = @_;
  my %param;
  if (open F,
      "svn cat '$main::svn_repos/mapreduce/mr-"
      .$mrfunction
      ."\@$rev' |")
  {
    foreach (<F>)
    {
      if (/^\#\#\#(MR_\w+):(\S+)/)
      {
	if (exists $param{$1})
	{
	  $param{$1} .= "\n$2";
	}
	else
	{
	  $param{$1} = $2;
	}
      }
    }
    close F;
  }
  return %param;
}

1;

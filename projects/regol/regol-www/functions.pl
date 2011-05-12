sub unescape
{
  local $_ = shift;
  s/\\n/\n/g;
  s/\\\\/\\/g;
  $_;
}

1;

sub unescape
{
  local $_ = shift;
  s/\\n/\n/g;
  s/\\\\/\\/g;
  $_;
}

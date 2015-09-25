#!perl -wT

require './t/CORE/test.pl';

for $file ( 't/CORE/re/subst.t', 're/subst.t', 't/re/subst.t', ':re:subst.t') {
  if (-r $file) {
    my ($tf) = $file =~ qr{(.*)};
    require "./$tf";
    exit;
  }
}
die "Cannot find re/subst.t or t/re/subst.t\n";

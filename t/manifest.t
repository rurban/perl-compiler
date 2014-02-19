# -*- perl -*-
use Test::More;
if ($^O != /^(linux|.*bsd|darwin|solaris|sunos)$/) {
  plan skip_all => "requires a unix for git and diff";
}
plan tests => 2;

system("git ls-tree -r --name-only HEAD >MANIFEST.git");
ok(-e "MANIFEST.git", "MANIFEST.git created with git ls-tree");
is(`diff -bu MANIFEST.git MANIFEST`, "", "MANIFEST.git compared to MANIFEST");
unlink "MANIFEST.git";

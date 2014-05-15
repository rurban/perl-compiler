# -*- perl -*-
use Test::More;
if (!-d ".git" or $^O != /^(linux|.*bsd|darwin|solaris|sunos)$/) {
  plan skip_all => "requires a git checkout and a unix for git and diff";
}
plan tests => 1;

system("git ls-tree -r --name-only HEAD >MANIFEST.git");
if (-e "MANIFEST.git") {
  diag "MANIFEST.git created with git ls-tree";
  is(`diff -bu MANIFEST.git MANIFEST`, "", "MANIFEST.git compared to MANIFEST");
  unlink "MANIFEST.git";
} else {
  ok(1, "skip no git");
}

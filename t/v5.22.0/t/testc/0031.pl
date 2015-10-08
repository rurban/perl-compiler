package MockShell;sub AUTOLOAD{my $p=$AUTOLOAD;$p=~s/.*:://;print(join(" ",$p,@_),";");} package main; MockShell::date();MockShell::who("am","i");MockShell::ls("-l");
### RESULT:date;who am i;ls -l;

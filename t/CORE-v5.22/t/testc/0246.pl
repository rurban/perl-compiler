sub foo($\@); eval q/foo "s"/; print $@
### RESULT:Not enough arguments for main::foo at (eval 1) line 1, at EOF

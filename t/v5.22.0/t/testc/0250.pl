#TODO version use warnings qw/syntax/; use version; $withversion::VERSION = undef; eval q/package withversion 1.1_;/; print $@;
### RESULT:Misplaced _ in number at (eval 1) line 1.
Invalid version format (no underscores) at (eval 1) line 1, near "package withversion "
syntax error at (eval 1) line 1, near "package withversion 1.1_"

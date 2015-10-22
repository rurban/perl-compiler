use strict; eval q({ $x = sub }); print $@
### RESULT:Illegal declaration of anonymous subroutine at (eval 1) line 1.

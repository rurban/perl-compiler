require B; my $x=1e1; my $s="$x"; print ref B::svref_2object(\$s)
### RESULT:B::PV

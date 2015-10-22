sub skip_on_odd{next NUMBER if $_[0]% 2}NUMBER:for($i=0;$i<5;$i++){skip_on_odd($i);print $i;}
### RESULT:024

use threads::shared;my @a : shared; $a[0]="ok"; print $a[0]
### RESULT:ok

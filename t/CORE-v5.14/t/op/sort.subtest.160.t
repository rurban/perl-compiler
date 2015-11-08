
   $sub = sub {
    local $count = $count+1;
    ()->$sub if $count < 1000;
    $a cmp $b
   };
   () = sort $sub qw<a b c d e f g>;
   print "ok"
 
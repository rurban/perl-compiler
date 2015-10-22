no warnings 'deprecated';
$[ = -2; $big = "N\xabN\xab"; $big .= chr 256; chop $big; print rindex $big, "N", 2 + $[
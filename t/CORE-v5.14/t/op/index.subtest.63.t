no warnings 'deprecated';
$[ = 0; $big = "N\xabN\xab"; $big .= chr 256; chop $big; print rindex $big, "N", 2 + $[
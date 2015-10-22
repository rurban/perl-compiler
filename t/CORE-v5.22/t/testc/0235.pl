BEGIN{$INC{"Carp.pm"}="/dev/null"} $d = pack("U*", 0xe3, 0x81, 0xAF); { use bytes; $ol = bytes::length($d) } print $ol
### RESULT:6

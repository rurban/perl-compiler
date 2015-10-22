use open qw(:std :utf8); BEGIN{ `echo ö > xx.bak`; } open X, "xx.bak"; $_ = <X>; print unpack("U*", $_), " "; print $_ if /\w/;
### RESULT:24610 ö

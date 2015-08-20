package B::IO;

use strict;

use Config;
use B qw/cstring svref_2object SVt_PVGV SVf_ROK/;
use B::C::File qw/init init2/;
use B::C::Helpers qw/mark_package/;
use B::C::Helpers::Symtable qw/objsym savesym/;

1;

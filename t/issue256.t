#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=256
# initialize all global vars
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
my $pv_vars = {';' => "\34",
               '"' => " ",
               #"\\" => undef,
               #',' => undef,
               '/' => "/n",
               '^A'  => undef,
               '^L'  => "\f",
               ':'  => " \n-",
               '^' => "STDOUT_TOP",
               '~' => "STDOUT"};
my $iv_vars = {'^H' => 0,
               '|' => 0,
               '%' => 0,
               '-' => 0,
               '=' => 60,
               #'{^UNICODE}' => 0,
               #'{^UTF8LOCALE}' => 1
               };
use Test::More tests => 2;

my $script = '';
$script .= sprintf('BEGIN{ $%s = "a"} $%s = "a"; print qq{not ok - \$%s = $%s\n} if $%s ne "a";'."\n", 
                   $_, $_, $_, $_, $_) for keys %$pv_vars;
$script .= sprintf('BEGIN{ $%s = 1} $%s = 1; print qq{not ok - \$%s = $%s\n} if $%s != 1;'."\n",
                   $_, $_, $_, $_, $_) for keys %$iv_vars;
$script .= 'BEGIN{ $\\ = "\n"; } $\\ = "\n"; print qq{not ok - \$\\ = $\\\n} if $\\ ne "\n";'."\n";
$script .= qq(print "ok\\n";);

ctestok(1,'C,-O3','ccode256i',$script,'#256 initialize most global vars');
ctestok(2,'C,-O3','ccode256i',
        'BEGIN{$, = " "; } $, = " "; print $, eq " " ? "ok\n" : qq{not ok - \$, = $,\n}',
        '#256 initialize $,');

# TODO: need -C switches to set the rest
#ctestok(3,'C,-O3','ccode256i',
#        'BEGIN{ ${^UNICODE} = 15; } ${^UNICODE} = 15; print qq{not ok - \${^UNICODE} = ${^UNICODE}\n} if ${^UNICODE} != 15;',
#        '#256 initialize ${^UNICODE}');
#ctestok(4,'C,-O3','ccode256i',
#        'BEGIN{ ${^UTF8LOCALE} = 2; } ${^UTF8LOCALE} = 2; print ${^UTF8LOCALE} == 2 ? "ok\n" : qq{not ok - \${^UTF8LOCALE} = ${^UTF8LOCALE}\n};',
#        '#256 initialize ${^UTF8LOCALE}');

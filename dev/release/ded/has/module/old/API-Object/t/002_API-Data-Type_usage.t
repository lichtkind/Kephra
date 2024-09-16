#!/usr/bin/perl -w
use v5.14;
use warnings;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::API::Data::Type qw/:all/;
use TestClass;
use Test::More tests => 12;

is( is_bool(1),                         1, 'recognize boolean value true');
is( is_bool(0),                         1, 'recognize boolean value false');
is( is_bool(''),                        0, 'empty is not boolean');
is( is_bool('der'),                     0, 'string is not boolean');
is( is_bool(2),                         0, 'int is not boolean');
is( is_bool(2.3),                       0, 'float is not boolean');

is( is_num(1.5),                        1, 'recognize number');
is( is_num('das'),                      0, 'string is not a number');


is( verify(1.5, 'num'),                 1, 'recognize number');
is( verify(1.5, 'num+'),                1, 'recognize positive number');
is( verify(5,   'int'),                 1, 'recognize integer');
is( verify(5,   'int+'),                1, 'recognize positive integer');


exit 0;

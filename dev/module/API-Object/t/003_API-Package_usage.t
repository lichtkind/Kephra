#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 14;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API::Package qw/package_loaded count_sub has_sub call_sub/;
use TestClass;

is( count_sub('TestClass'),                     7, 'TestClass has 6 subs');
is( count_sub('Class'),                         0, 'Class has 0 subs, no existing package');
is( count_sub(),                            undef, 'got undef because called count_sub without params');
is( package_loaded('TestClass'),                1, 'TestClass is loaded package');
is( package_loaded('Class'),                    0, 'Class is not loaded');
is( package_loaded(),                       undef, 'got undef because called package_loaded without params');
is( has_sub('TestClass', 'get'),                1, 'TestClass::get is a real sub');
is( has_sub('TestClass', 'blu'),                0, 'TestClass::blu is not a real sub');
is( has_sub('TestClass'),                       0, 'a package is not a sub');
is( has_sub(),                              undef, 'got undef because called has_sub with missing params');
is( (call_sub('TestClass::ret', 's',7))[0],     7, 'got right return value for calling a sub through table');
is( (call_sub('TestClass::ret'))[0],        undef, 'got right return value for calling a sub with no params');
is( call_sub('TestClass::ret'),                 0, 'no params in - no params out');
is( call_sub(),                             undef, 'got undef because called call_sub with missing params');

exit 0;

#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 62;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! do not edit - line number are part of tests !!!!!!!!!!!!!!!!!!!!

use Kephra::Base::Package qw/:all/;
use TestClass;

is( package_loaded('TestClass'),                1, 'TestClass is loaded package');
is( package_loaded('Class'),                    0, 'Class is not loaded');
is( package_loaded(),                       undef, 'got undef because called package_loaded without params');

is( count_sub('TestClass'),                     7, 'TestClass has 6 subs');
is( count_sub('Class'),                         0, 'Class has 0 subs, no existing package');
is( count_sub(),                            undef, 'got undef because called count_sub without params');

is( has_sub('TestClass', 'get'),                1, 'TestClass::get is a real sub');
is( has_sub('TestClass', 'blu'),                0, 'TestClass::blu is not a defined sub');
is( has_sub('TestClass'),                       0, 'a package is not a sub');
is( has_sub(),                              undef, 'got undef because called has_sub with missing params');

my $s = sub{3};
is( get_sub('TestClass', 'two'),            undef, 'can not retrieve code ref, it is not there yet');
is( TestClass::one(),                           1, 'TestClass::one returns 1');
is( set_sub('TestClass', 'one', sub{2}),        1, 'rewrote TestClass::one with 3 parameters');
is( TestClass::one(),                           2, 'TestClass::one returns 2');
is( set_sub('TestClass::one', $s),              1, 'rewrote TestClass::one with 2 parameters');
is( TestClass::one(),                           3, 'TestClass::one returns 3');
is( get_sub('TestClass::one'),                 $s, 'got our selfmade routine back');
is( get_sub('TestClass::one')->(),              3, 'called self made routine via getter');
is( get_sub('TestClass','one')->(),             3, 'got self made routine via getter when requested via name parts');
is( set_sub('TestClass::one', {}),              0, 'reject to set HASH ref into CODE slot');
is( set_sub('TestClass::one', []),              0, 'reject to set ARRAY ref into CODE slot');
is( get_sub('TestClass','one')->(),             3, 'still same code ref under the name (aafter bad set trials)');

is( (call_sub('TestClass::ret', 's',7))[0],     7, 'got right return value for calling a sub through table');
is( (call_sub('TestClass::ret'))[0],        undef, 'got right return value for calling a sub with no params');
is( call_sub('TestClass::ret'),                 0, 'no params in - no params out');
is( call_sub(),                             undef, 'got undef because called call_sub with missing params');

my @call_data = B::caller();
is( $call_data[0],                            'B', 'simply was called from right package');
is( $call_data[1],                       'caller', 'simply was called from right sub');
is( $call_data[2],                       __FILE__, 'simply was called from right file');
is( $call_data[3],                             97, 'simply was called from right line');

@call_data = A::deep_caller();
is( $call_data[0],                            'B', 'deep was called from right package');
is( $call_data[1],                       'caller', 'deep was called from right sub');
is( $call_data[2],                       __FILE__, 'deep was called from right file');
is( $call_data[3],                             97, 'deep was called from right line');

@call_data = A::deep_caller(2);
is( $call_data[0],                            'A', 'was called from right package');
is( $call_data[1],                  'deep_caller', 'was called from right sub');
is( $call_data[2],                       __FILE__, 'was called from right file');
is( $call_data[3],                             94, 'was called from right line');

my $h = {1 => 2};
is( get_hash('TestClass', 'h'),             undef, 'can not retrieve hash, it is not there yet');
is( has_hash('TestClass', 'h'),                 0, 'hash is not there yet');
is( has_hash('TestClass::h'),                   0, 'hash is also not there yet if ask with full name');
is( set_hash('TestClass','h', $h),              1, 'set hash');
is( has_hash('TestClass', 'h'),                 1, 'hash is now there');
is( has_hash('TestClass::h'),                   1, 'hash is also now there, asked with full name');
is( get_hash('TestClass','h'),                 $h, 'got same hash ref back');
is( $h->{1},                                    2, 'content not changed');
is( scalar(keys %$h),                           1, 'content got not more');
is( set_hash('TestClass::h', []),               0, 'set array to hash slot');
is( set_hash('TestClass::h', sub{}),            0, 'set code to hash slot');
is( get_hash('TestClass','h'),                 $h, 'same hash is still there');

my $a = [3];
is( get_array('TestClass', 'a'),            undef, 'can not retrieve array, it is not there yet');
is( has_array('TestClass', 'a'),                0, 'array is not there yet');
is( has_array('TestClass::a'),                  0, 'array is also not there yet if ask with full name');
is( set_array('TestClass','a', $a),             1, 'set array');
is( has_array('TestClass', 'a'),                1, 'array is now there');
is( has_array('TestClass::a'),                  1, 'array is also now there, asked with full name');
is( get_array('TestClass','a'),                $a, 'got same array ref back');
is( $a->[0],                                    3, 'content not changed');
is( scalar(@$a),                                1, 'content got not more');
is( set_array('TestClass::a', {}),              0, 'set hash to array slot');
is( set_array('TestClass::a', sub{}),           0, 'set code to array slot');
is( get_array('TestClass','a'),                $a, 'same array is still there');

exit 0;

package A;
sub deep_caller { B::caller( shift ) }

package B;
sub caller      { C::called( shift ) }

package C;
sub called      { Kephra::Base::Package::sub_caller( shift) }


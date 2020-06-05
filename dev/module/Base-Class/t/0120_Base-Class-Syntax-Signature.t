#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/switch/;
use Test::More tests => 90;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Syntax::Signature;

sub parse{ Kephra::Base::Class::Syntax::Signature::parse(@_) }

my $data = parse('  ');
is(ref $data,     'ARRAY',       'empty signature still produces ARRAY data structure');
is(@$data,              3,       'empty signature still produces data structure of minimal length');
is($data->[0],          0,       'empty sig has no required arguments');
is($data->[1],          0,       'empty sig has no optional arguments');
is($data->[2],          0,       'empty sig has no return values');

$data = parse('');
is(ref $data,     'ARRAY',       'no signature still produces ARRAY data structure');
is(@$data,              3,       'no signature still produces data structure of minimal length');
is($data->[0],          0,       'no sig has no required arguments');
is($data->[1],          0,       'no sig has no optional arguments');
is($data->[2],          0,       'no sig has no return values');

$data = parse(undef);
is(ref $data,     'ARRAY',       'undef signature still produces ARRAY data structure');
is(@$data,              3,       'undef signature still produces data structure of minimal length');
is($data->[0],          0,       'undef sig has no required arguments');
is($data->[1],          0,       'undef sig has no optional arguments');
is($data->[2],          0,       'undef sig has no return values');

$data = parse(' - --> ');
is(ref $data,     'ARRAY',       'blank signature - --> produces ARRAY data structure');
is(@$data,              4,       'blank signature still produces data structure of minimal length + 1');
is($data->[0],          0,       'blank sig has no required arguments');
is($data->[1],          0,       'blank sig has no optional arguments');
is($data->[2],          1,       'blank sig has one return values');
is(@{$data->[3]},       3,       'return value definition has three parts');
is($data->[3][2],  'pass',       'blank sig passes all return values');

$data = parse(' arg - ');
is(ref $data,     'ARRAY',       'signature with one required argument');
is(@$data,              4,       '1 req signature still produces data structure of minimal length + 1');
is($data->[0],          1,       '1 req sig has one required argument');
is($data->[1],          0,       '1 req sig has no optional arguments');
is($data->[2],          0,       '1 req sig has no return value');
is(@{$data->[3]},       1,       'argument definition has one part');
is($data->[3][0],   'arg',       'name of first argument');

$data = parse('int arg - bet --> ');
is(ref $data,     'ARRAY',       'one typed required and onne optional and passing return value');
is(@$data,              6,       '1T 1 1 signature still produces data structure of minimal length + 3');
is($data->[0],          1,       '1T 1 1 sig has one required argument');
is($data->[1],          1,       '1T 1 1 sig has one optional arguments');
is($data->[2],          1,       '1T 1 1 sig has one nominal return value');
is(@{$data->[3]},       2,       'required argument definition has two part');
is($data->[3][0],   'arg',       'name of first argument');
is($data->[3][1],   'int',       'type of first argument');
is(@{$data->[4]},       1,       'optional argument definition has one part');
is($data->[4][0],   'bet',       'name of second argument');

exit 0;
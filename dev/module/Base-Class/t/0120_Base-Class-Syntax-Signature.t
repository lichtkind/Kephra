#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/switch/;
use Test::More tests => 120;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Syntax::Signature;

sub parse{ Kephra::Base::Class::Syntax::Signature::parse(@_) }

my $data = parse('  ');
is(ref $data,       'ARRAY',       'empty signature still produces ARRAY data structure');
is(@$data,                3,       'empty signature still produces data structure of minimal length');
is($data->[0],            0,       'empty sig has no required arguments');
is($data->[1],            0,       'empty sig has no optional arguments');
is($data->[2],            0,       'empty sig has no return values');

$data = parse('');
is(ref $data,       'ARRAY',       'no signature still produces ARRAY data structure');
is(@$data,                3,       'no signature still produces data structure of minimal length');
is($data->[0],            0,       'no sig has no required arguments');
is($data->[1],            0,       'no sig has no optional arguments');
is($data->[2],            0,       'no sig has no return values');

$data = parse(undef);
is(ref $data,       'ARRAY',       'undef signature still produces ARRAY data structure');
is(@$data,                3,       'undef signature still produces data structure of minimal length');
is($data->[0],            0,       'undef sig has no required arguments');
is($data->[1],            0,       'undef sig has no optional arguments');
is($data->[2],            0,       'undef sig has no return values');

$data = parse(' - --> ');
is(ref $data,       'ARRAY',       'blank signature - --> produces ARRAY data structure');
is(@$data,                4,       'blank signature still produces data structure of minimal length + 1');
is($data->[0],            0,       'blank sig has no required arguments');
is($data->[1],            0,       'blank sig has no optional arguments');
is($data->[2],            1,       'blank sig has one return values');
is(@{$data->[3]},         3,       'return value definition has three parts');
is($data->[3][2],    'pass',       'blank sig passes all return values');

$data = parse(' arg - ');
is(ref $data,       'ARRAY',       'signature with one required argument');
is(@$data,                4,       '1 req signature still produces data structure of minimal length + 1');
is($data->[0],            1,       '1 req sig has one required argument');
is($data->[1],            0,       '1 req sig has no optional arguments');
is($data->[2],            0,       '1 req sig has no return value');
is(@{$data->[3]},         1,       'argument definition has one part');
is($data->[3][0],     'arg',       'name of first argument');

$data = parse('int arg -bet--> ');
is(ref $data,       'ARRAY',       'one typed required and onne optional and passing return value');
is(@$data,                6,       '1T 1 1 signature still produces data structure of minimal length + 3');
is($data->[0],            1,       '1T 1 1 sig has one required argument');
is($data->[1],            1,       '1T 1 1 sig has one optional arguments');
is($data->[2],            1,       '1T 1 1 sig has one nominal return value');
is(@{$data->[3]},         2,       'required argument definition has two parts');
is($data->[3][0],     'arg',       'name of first argument');
is($data->[3][1],     'int',       'type of first argument');
is(@{$data->[4]},         1,       'optional argument definition has one part');
is($data->[4][0],     'bet',       'name of second argument');

$data = parse('-index of array arg , str b, ~ text --> ?');
is(ref $data,       'ARRAY',       'parse sig:  - index of array arg , str b ~ text --> ?');
is(@$data,                7,       'has 4 arguments');
is($data->[0],            0,       'no  required arguments');
is($data->[1],            3,       '3 optional arguments');
is($data->[2],            1,       'one return value');
is(@{$data->[3]},         4,       'first optional argument definition has four parts');
is($data->[3][0],     'arg',       'name of first argument');
is($data->[3][1],   'index',       'main type of first argument');
is($data->[3][2],    'type',       'first argument has parametric type');
is($data->[3][3],   'array',       'parametric type of first argument');
is(@{$data->[4]},         2,       'second optional argument definition has one part');
is($data->[4][0],       'b',       'name of second argument');
is($data->[4][1],     'str',       'type of second argument');
is(@{$data->[5]},         2,       'third optional argument definition has two parts');
is($data->[5][0],    'text',       'name of third optional argument');
is($data->[5][1],       '~',       'type of first optional argument');
is(@{$data->[6]},         2,       'return value definition has two parts');
is($data->[6][0],'return_value_1', 'name of first return value');
is($data->[6][1],       '?',       'type of second argument');

$data = parse('  -@~text--> index of .wide, index of argument went');
is(ref $data,       'ARRAY',       'parse sig:  -@~text--> index of .wide, index of argument went');
is(@$data,                6,       'has 3 arguments');
is($data->[0],            0,       'no required arguments');
is($data->[1],            1,       '1 optional argument');
is($data->[2],            2,       'two return values');
is(@{$data->[3]},         4,       'optional argument definition has four parts');
is($data->[3][0],    'text',       'name of first argument');
is($data->[3][1],       '@',       'main type of first argument');
is($data->[3][2],    'type',       'first argument has parametric type');
is($data->[3][3],       '~',       'parametric type of first argument');
is(@{$data->[4]},         4,       'first return value definition has four parts');
is($data->[4][0], 'return_value_1','name of first retval');
is($data->[4][1],   'index',       'main type of first retval');
is($data->[4][2],    'attr',       'parameter of first retval is an attribute');
is($data->[4][3],    'wide',       'attribute name that holds paramter value of first retval');
is(@{$data->[5]},         4,       'second return value definition has four parts');
is($data->[5][0], 'return_value_2','name of second retval');
is($data->[5][1],   'index',       'main type of second retval');
is($data->[5][2],     'arg',       'parameter of first retval is an argument');
is($data->[5][3],    'went',       'argument name that holds paramter value of second retval');

$data = parse('.name,>@rest');
is(ref $data,       'ARRAY',       'parse sig: .name,>@');
is(@$data,                5,       'has 2 arguments');
is($data->[0],            2,       'two required arguments');
is($data->[1],            0,       'no optional argument');
is($data->[2],            0,       'no return values');
is(@{$data->[3]},         3,       'first required argument definition has three parts');
is($data->[3][0],    'name',       'name of first argument');
is($data->[3][1],        '',       'first required argument has no own type');
is($data->[3][2],'foreward',       'first argument gets forewarded to attribute of same name');
is(@{$data->[4]},         3,       'second argument definition has three parts');
is($data->[4][0],    'rest',       'name of second argument');
is($data->[4][1],        '',       'second required argument has no type');
is($data->[4][2],   'slurp',       'second argument is slurpy');

$data = parse('index of attribute bit a,Inum , Zint dat-->ref of arg a');
is(ref $data,       'ARRAY',       'parse sig: index of attribute bit a --> ref of arg a');
is(@$data,                7,       'has 4 arguments');
is($data->[0],            3,       'three required arguments');
is($data->[1],            0,       'no optional argument');
is($data->[2],            1,       'one return value');
is(@{$data->[3]},         4,       'first required argument definition has four parts');
is($data->[3][0],       'a',       'name of first argument');
is($data->[3][1],   'index',       'main type of first required argumen');
is($data->[3][2],    'attr',       'first argument to attribute of same name');
is($data->[3][3],     'bit',       'first argument to attribute of same name');
is(@{$data->[4]},         2,       'second required argument definition has two parts');
is($data->[4][0],     'num',       'name of second argument');
is($data->[4][1],       'I',       'type of second argument');
is(@{$data->[5]},         4,       'third required argument definition has four parts');
is($data->[5][0],     'dat',       'name of third argument');
is($data->[5][1],       'Z',       'main type of third argument');
is($data->[5][2],    'type',       'source or parameter type of third argument');
is($data->[5][3],     'int',       'parameter type of third argument');
is(@{$data->[6]},         4,       'return value definition has four parts');
is($data->[6][0],'return_value_1', 'name of return value');
is($data->[6][1],     'ref',       'main type of return value');
is($data->[6][2],     'arg',       'parameter value source for return value');
is($data->[6][3],       'a',       'parameter name for return value');

$data = parse(')a');
is(ref $data,       'ARRAY',       'parse sig: )a');
is(@$data,                4,       'has 1 arguments');
is($data->[0],            1,       'one required argument');
is($data->[1],            0,       'no optional argument');
is($data->[2],            0,       'no return value');
is(@{$data->[3]},         2,       'first required argument definition has two parts');



exit 0;
#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/switch/;
use Test::More tests => 110;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Syntax::Signature;

sub parse{ Kephra::Base::Class::Syntax::Signature::parse(@_) }

my $data = parse('  ');
is(ref $data,            'HASH',       'empty signature still produces HASH data structure');
is(ref $data->{'req'},       '',       'empty sig has no required arguments');
is(ref $data->{'opt'},       '',       'empty sig has no optional arguments');
is(ref $data->{'ret'},       '',       'empty sig has no return values');

$data = parse('');
is(ref $data,            'HASH',       'no signature still produces HASH data structure');
is(ref $data->{'req'},       '',       'no sig has no required arguments');
is(ref $data->{'opt'},       '',       'no sig has no optional arguments');
is(ref $data->{'ret'},       '',       'no sig has no return values');

$data = parse(undef);
is(ref $data,            'HASH',       'undef signature still produces HASH data structure');
is(ref $data->{'req'},       '',       'undef sig has no required arguments');
is(ref $data->{'opt'},       '',       'undef sig has no optional arguments');
is(ref $data->{'ret'},       '',       'undef sig has no return values');

$data = parse(' - --> ');
is(ref $data,            'HASH',       'blank signature - --> produces HASH data structure');
is(ref $data->{'req'},       '',       'blank sig has no required arguments');
is($data->{'opt'},           '',       'blank sig has no optional arguments');
is(ref $data->{'ret'},  'ARRAY',       'blank allows return values');
is( @{$data->{'ret'}},        0,       'blank sig passses return values');

$data = parse(' arg - ');
is(ref $data,            'HASH',       'signature with one required argument:  arg - ');
is(@{$data->{'req'}},         1,       '1 req sig has one required argument');
is($data->{'opt'},           '',       '1 req sig has no optional arguments');
is($data->{'ret'},           '',       '1 req sig has no return value');
is(ref $data->{'req'}[0],    '',       'argument has only a name');
is($data->{'req'}[0],     'arg',       'name of first argument');

$data = parse('int arg -bet--> ');
is(ref $data,            'HASH',       'parse sig: int arg -bet--> ');
is(@{$data->{'req'}},         1,       'has one required argument');
is(@{$data->{'opt'}},         1,       'has one optional argument');
is(ref $data->{'ret'},  'ARRAY',       'has one nominal return value');
is( @{$data->{'ret'}},        0,       'but passses just return values');
is(@{$data->{'req'}[0]},      2,       'required argument def has 2 parts');
is($data->{'req'}[0][0],  'arg',       'name of first argument');
is($data->{'req'}[0][1],  'int',       'type of first argument');
is($data->{'opt'}[0],     'bet',       'name of second argument');

$data = parse('- index of array arg , str b, ~ text --> ?');
is(ref $data,            'HASH',       'parse sig:  - index of array arg , str b ~ text --> ?');
is($data->{'req'},           '',       'has no required argument');
is(@{$data->{'opt'}},         3,       'has 3 optional arguments');
is(@{$data->{'ret'}},         1,       'has 1 return value');
is(@{$data->{'opt'}[0]},      4,       'first argument def has 4 parts');
is($data->{'opt'}[0][0],  'arg',       'name of first optional argument');
is($data->{'opt'}[0][1],'index',       'main type of first, optional argument');
is($data->{'opt'}[0][2], 'type',       'first, optional argument has type as parameter');
is($data->{'opt'}[0][3],'array',       'parameter type of first, optional argument');
is(@{$data->{'opt'}[1]},      2,       'second argument def has 2 parts');
is($data->{'opt'}[1][0],    'b',       'name of second optional argument');
is($data->{'opt'}[1][1],  'str',       'type of second optional argument');
is(@{$data->{'opt'}[1]},      2,       'third argument def has 2 parts');
is($data->{'opt'}[2][0], 'text',       'name of third optional argument');
is($data->{'opt'}[2][1],    '~',       'type of third optional argument');
is(@{$data->{'ret'}[0]},      2,       'return value def has 2 parts');
is($data->{'ret'}[0][0],'return_value_1','name of first return value');
is($data->{'ret'}[0][1],    '?',       'type of first return value');

$data = parse('  -@~text--> index of .wide, index of argument went');
is(ref $data,            'HASH',       'parse sig:  -@~text--> index of .wide, index of argument went');
is($data->{'req'},           '',       'has no required argument');
is(@{$data->{'opt'}},         1,       'has 1 optional argument');
is(@{$data->{'ret'}},         2,       'has 2 return values');
is(@{$data->{'opt'}[0]},      4,       'first argument def has 4 parts');
is($data->{'opt'}[0][0], 'text',       'name of first optional argument');
is($data->{'opt'}[0][1],    '@',       'main type of first, optional argument');
is($data->{'opt'}[0][2], 'type',       'first, optional argument has type as parameter');
is($data->{'opt'}[0][3],    '~',       'parameter type of first, optional argument');
is(@{$data->{'ret'}[0]},      4,       'first return value def has 4 parts');
is($data->{'ret'}[0][0],'return_value_1','name of first return value');
is($data->{'ret'}[0][1],'index',       'main type of first return value');
is($data->{'ret'}[0][2], 'attr',       'parameter of return value is an attribute');
is($data->{'ret'}[0][3], 'wide',       'name of the attribute');
is(@{$data->{'ret'}[1]},      4,       'second return value def has 4 parts');
is($data->{'ret'}[1][0],'return_value_2','name of second return value');
is($data->{'ret'}[1][1],'index',       'main type of second return value');
is($data->{'ret'}[1][2],  'arg',       'second return parameter is an argument');
is($data->{'ret'}[1][3], 'went',       'argument name');

$data = parse('.name,>@rest');
is(ref $data,            'HASH',       'parse sig: .name,>@');
is(@{$data->{'req'}},         2,       'has 2 required arguments');
is($data->{'opt'},           '',       'has no optional argument');
is($data->{'ret'},           '',       'has no return value');
is(@{$data->{'req'}[0]},      3,       'first argument def has 3 parts');
is($data->{'req'}[0][0], 'name',       'name of first argument');
is($data->{'req'}[0][1],     '',       'no type yet for first argument');
is($data->{'req'}[0][2],'foreward',    'it is an foreward argument');
is(@{$data->{'req'}[1]},      3,       'second argument def has 3 parts');
is($data->{'req'}[1][0], 'rest',       'name of second argument');
is($data->{'req'}[1][1],     '',       'no type yet for second argument');
is($data->{'req'}[1][2],'slurp',       'it is an slurpy argument');

$data = parse('index of attribute bit a,Inum , Zint dat-->ref of arg a');
is(ref $data,            'HASH',       'parse sig: index of attribute bit a --> ref of arg a');
is(@{$data->{'req'}},         3,       'has 3 required arguments');
is($data->{'opt'},           '',       'has no optional argument');
is(@{$data->{'ret'}},         1,       'has 1 return value');
is(@{$data->{'req'}[0]},      4,       'first argument def has 4 parts');
is($data->{'req'}[0][0],    'a',       'name of first argument');
is($data->{'req'}[0][1],'index',       'main type of first argument');
is($data->{'req'}[0][2], 'attr',       'type parameter is an attribute');
is($data->{'req'}[0][3],  'bit',       'attribute name');
is(@{$data->{'req'}[1]},      2,       'second argument def has 2 parts');
is($data->{'req'}[1][0],  'num',       'name of second argument');
is($data->{'req'}[1][1],    'I',       'type of second argument');
is(@{$data->{'req'}[2]},      4,       'third argument def has 4 parts');
is($data->{'req'}[2][0],  'dat',       'name of third argument');
is($data->{'req'}[2][1],    'Z',       'main type of third argument');
is($data->{'req'}[2][2], 'type',       'parameter is an type');
is($data->{'req'}[2][3],  'int',       'type name');
is(@{$data->{'ret'}[0]},      4,       'first return value def has 4 parts');
is($data->{'ret'}[0][0],'return_value_1','name of first return value');
is($data->{'ret'}[0][1],  'ref',       'main type of first return value');
is($data->{'ret'}[0][2],  'arg',       'parameter of return value is an argument');
is($data->{'ret'}[0][3],    'a',       'name of the argument');

$data = parse(')a,-,');
is(ref $data,            'HASH',       'parse sig: )a,-,');
is(@{$data->{'req'}},         1,       'has 1 required argument');
is($data->{'opt'},           '',       'has no optional argument');
is($data->{'ret'},           '',       'has no return value');
is(@{$data->{'req'}[0]},      2,       'first argument def has 2 parts');
is($data->{'req'}[0][0],    'a',       'name of first argument');
is($data->{'req'}[0][1],    ')',       'main type of first argument');



exit 0;

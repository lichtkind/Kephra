#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/switch/;
use Test::More tests => 150;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Syntax::Signature;

sub parse{ Kephra::Base::Class::Syntax::Signature::parse(@_) }

my $data = parse('  ');
is(ref $data,                 'HASH',       'empty signature still produces HASH data structure');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'empty sig has slot for required arguments');
is(ref $data->{'required'},       '',       'empty sig has no required arguments');
is(exists $data->{'optional'},     1,       'empty sig has slot for optional arguments');
is(ref $data->{'optional'},       '',       'empty sig has no optional arguments');
is(exists $data->{'return'},       1,       'empty sig has slot for return values');
is(ref $data->{'return'},         '',       'empty sig has no return values');

$data = parse('');
is(ref $data,                 'HASH',       'no signature still produces HASH data structure');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'no sig has slot for required arguments');
is(ref $data->{'required'},       '',       'no sig has no required arguments');
is(exists $data->{'optional'},     1,       'no sig has slot for optional arguments');
is(ref $data->{'optional'},       '',       'no sig has no optional arguments');
is(exists $data->{'return'},     1,         'no sig has slot for return values');
is(ref $data->{'return'},         '',       'no sig has no return values');

$data = parse(undef);
is(ref $data,                 'HASH',       'undef signature still produces HASH data structure');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'undef sig has slot for required arguments');
is(ref $data->{'required'},       '',       'undef sig has no required arguments');
is(exists $data->{'optional'},     1,       'undef sig has slot for optional arguments');
is(ref $data->{'optional'},       '',       'undef sig has no optional arguments');
is(exists $data->{'return'},       1,       'undef sig has slot for return values');
is(ref $data->{'return'},         '',       'undef sig has no return values');

$data = parse(' - --> ');
is(ref $data,                 'HASH',       'blank signature - --> produces HASH data structure');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'blank sig has slot for required arguments');
is(ref $data->{'required'},       '',       'blank sig has no required arguments');
is(exists $data->{'optional'},     1,       'blank sig has slot for optional arguments');
is($data->{'optional'},           '',       'blank sig has no optional arguments');
is(exists $data->{'return'},       1,       'blank sig has slot for return values');
is(ref $data->{'return'},    'ARRAY',       'blank allows return values');
is( @{$data->{'return'}},          0,       'blank sig passses return values');

$data = parse(' arg - ');
is(ref $data,                 'HASH',       'signature with one required argument:  arg - ');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       '1 req sig has slot for required arguments');
is(@{$data->{'required'}},         1,       '1 req sig has one required argument');
is(ref $data->{'required'}[0],    '',       'argument has only a name');
is($data->{'required'}[0],     'arg',       'name of first argument');
is(exists $data->{'optional'},     1,       '1 req sig has slot for required arguments');
is($data->{'optional'},           '',       '1 req sig has no optional arguments');
is(exists $data->{'return'},       1,       '1 req sig has slot for required arguments');
is($data->{'return'},             '',       '1 req sig has no return value');

$data = parse('int arg -bet--> ');
is(ref $data,                 'HASH',       'parse sig: int arg -bet--> ');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'signature definition has slot for required arguments');
is(@{$data->{'required'}},         1,       'has one required argument');
is(@{$data->{'required'}[0]},      2,       'required argument def has 2 parts');
is($data->{'required'}[0][0],  'arg',       'name of first argument');
is($data->{'required'}[0][1],  'int',       'type of first argument');
is(exists $data->{'optional'},     1,       'signature definition has slot for optional arguments');
is(@{$data->{'optional'}},         1,       'has one optional argument');
is($data->{'optional'}[0],     'bet',       'name of second argument');
is(exists $data->{'return'},       1,       'signature definition has slot for required arguments');
is(ref $data->{'return'},    'ARRAY',       'has one nominal return value');
is( @{$data->{'return'}},          0,       'but passses just return values');

$data = parse('- index of array arg , str b, ~ text --> ?');
is(ref $data,                 'HASH',       'parse sig:  - index of array arg , str b ~ text --> ?');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'signature definition has slot for required arguments');
is($data->{'required'},           '',       'has no required argument');
is(exists $data->{'optional'},     1,       'signature definition has slot for optional arguments');
is(@{$data->{'optional'}},         3,       'has 3 optional arguments');
is(@{$data->{'optional'}[0]},      4,       'first argument def has 4 parts');
is($data->{'optional'}[0][0],  'arg',       'name of first optional argument');
is($data->{'optional'}[0][1],'index',       'main type of first, optional argument');
is($data->{'optional'}[0][2], 'type',       'first, optional argument has type as parameter');
is($data->{'optional'}[0][3],'array',       'parameter type of first, optional argument');
is(@{$data->{'optional'}[1]},      2,       'second argument def has 2 parts');
is($data->{'optional'}[1][0],    'b',       'name of second optional argument');
is($data->{'optional'}[1][1],  'str',       'type of second optional argument');
is(@{$data->{'optional'}[1]},      2,       'third argument def has 2 parts');
is($data->{'optional'}[2][0], 'text',       'name of third optional argument');
is($data->{'optional'}[2][1],    '~',       'type of third optional argument');
is(exists $data->{'return'},       1,       'signature definition has slot for required arguments');
is(@{$data->{'return'}},           1,       'has 1 return value');
is(@{$data->{'return'}[0]},        2,       'return value def has 2 parts');
is($data->{'return'}[0][0],'return_value_1','name of first return value');
is($data->{'return'}[0][1],      '?',       'type of first return value');

$data = parse('  -@~text--> index of .wide, index of argument went');
is(ref $data,                 'HASH',       'parse sig:  -@~text--> index of .wide, index of argument went');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'signature definition has slot for required arguments');
is($data->{'required'},           '',       'has no required argument');
is(exists $data->{'optional'},     1,       'signature definition has slot for optional arguments');
is(@{$data->{'optional'}},         1,       'has 1 optional argument');
is(@{$data->{'optional'}[0]},      4,       'first argument def has 4 parts');
is($data->{'optional'}[0][0], 'text',       'name of first optional argument');
is($data->{'optional'}[0][1],    '@',       'main type of first, optional argument');
is($data->{'optional'}[0][2], 'type',       'first, optional argument has type as parameter');
is($data->{'optional'}[0][3],    '~',       'parameter type of first, optional argument');
is(exists $data->{'return'},       1,       'signature definition has slot for required arguments');
is(@{$data->{'return'}},           2,       'has 2 return values');
is(@{$data->{'return'}[0]},        4,       'first return value def has 4 parts');
is($data->{'return'}[0][0],'return_value_1','name of first return value');
is($data->{'return'}[0][1],  'index',       'main type of first return value');
is($data->{'return'}[0][2],   'attr',       'parameter of return value is an attribute');
is($data->{'return'}[0][3],   'wide',       'name of the attribute');
is(@{$data->{'return'}[1]},        4,       'second return value def has 4 parts');
is($data->{'return'}[1][0],'return_value_2','name of second return value');
is($data->{'return'}[1][1],  'index',       'main type of second return value');
is($data->{'return'}[1][2],    'arg',       'second return parameter is an argument');
is($data->{'return'}[1][3],   'went',       'argument name');

$data = parse('.name,>@rest');
is(ref $data,                 'HASH',       'parse sig: .name,>@');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'signature definition has slot for required arguments');
is(@{$data->{'required'}},         2,       'has 2 required arguments');
is(@{$data->{'required'}[0]},      3,       'first argument def has 3 parts');
is($data->{'required'}[0][0], 'name',       'name of first argument');
is($data->{'required'}[0][1],     '',       'no type yet for first argument');
is($data->{'required'}[0][2],'foreward',    'it is an foreward argument');
is(@{$data->{'required'}[1]},      3,       'second argument def has 3 parts');
is($data->{'required'}[1][0], 'rest',       'name of second argument');
is($data->{'required'}[1][1],     '',       'no type yet for second argument');
is($data->{'required'}[1][2],'slurp',       'it is an slurpy argument');
is(exists $data->{'optional'},     1,       'signature definition has slot for optional arguments');
is($data->{'optional'},           '',       'has no optional argument');
is(exists $data->{'return'},       1,       'signature definition has slot for required arguments');
is($data->{'return'},             '',       'has no return value');

$data = parse('index of attribute bit a,Inum , Zint dat-->ref of arg a');
is(ref $data,                 'HASH',       'parse sig: index of attribute bit a --> ref of arg a');
is(keys %{$data},                  3,       'signature definition has to have only three parts');
is(exists $data->{'required'},     1,       'signature definition has slot for required arguments');
is(@{$data->{'required'}},         3,       'has 3 required arguments');
is(@{$data->{'required'}[0]},      4,       'first argument def has 4 parts');
is($data->{'required'}[0][0],    'a',       'name of first argument');
is($data->{'required'}[0][1],'index',       'main type of first argument');
is($data->{'required'}[0][2], 'attr',       'type parameter is an attribute');
is($data->{'required'}[0][3],  'bit',       'attribute name');
is(@{$data->{'required'}[1]},      2,       'second argument def has 2 parts');
is($data->{'required'}[1][0],  'num',       'name of second argument');
is($data->{'required'}[1][1],    'I',       'type of second argument');
is(@{$data->{'required'}[2]},      4,       'third argument def has 4 parts');
is($data->{'required'}[2][0],  'dat',       'name of third argument');
is($data->{'required'}[2][1],    'Z',       'main type of third argument');
is($data->{'required'}[2][2], 'type',       'parameter is an type');
is($data->{'required'}[2][3],  'int',       'type name');
is(exists $data->{'optional'},     1,       'signature definition has slot for optional arguments');
is($data->{'optional'},           '',       'has no optional argument');
is(exists $data->{'return'},       1,       'signature definition has slot for required arguments');
is(@{$data->{'return'}},           1,       'has 1 return value');
is(@{$data->{'return'}[0]},        4,       'first return value def has 4 parts');
is($data->{'return'}[0][0],'return_value_1','name of first return value');
is($data->{'return'}[0][1],    'ref',       'main type of first return value');
is($data->{'return'}[0][2],    'arg',       'parameter of return value is an argument');
is($data->{'return'}[0][3],      'a',       'name of the argument');

$data = parse(')a,-,');
is(ref $data,                 'HASH',       'parse sig: )a,-,');
is(@{$data->{'required'}},         1,       'has 1 required argument');
is(@{$data->{'required'}[0]},      2,       'first argument def has 2 parts');
is($data->{'required'}[0][0],    'a',       'name of first argument');
is($data->{'required'}[0][1],    ')',       'main type of first argument');
is($data->{'optional'},           '',       'has no optional argument');
is($data->{'return'},             '',       'has no return value');

exit 0;

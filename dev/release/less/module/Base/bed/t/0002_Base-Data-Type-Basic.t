#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Test::More tests => 171;

my $pkg = 'Kephra::Base::Data::Type::Basic';
sub create_type { Kephra::Base::Data::Type::Basic->new(@_) }
my $check = \&Kephra::Base::Data::Type::Basic::_check_name;

eval "use $pkg;";
is( $@, '',                                     'could load the module '.$pkg);

like( $check->(),    qr/not defined/,           'type name chacker has to have a have input');
like( $check->('-'),  qr/only lower case/,      'type name have char set restrictions');
like( $check->('0bs'), qr/start with a letter/, 'type name are char first');
like( $check->('bs'), qr/at least 3 character/, 'type name have min 3 chars');
like( $check->('abcdabcdabcdabcde'), qr/not be longer/, 'type name have max 16 chars');


my $vh = 'not a reference'; # type value help
my $vc = 'not ref $value'; # type value code
my $Tvalue = create_type('value', $vh, $vc, undef, '');
is( ref $Tvalue, $pkg,                'created first type object "value"');
is( $Tvalue->kind, 'basic',           'got attribute "kind" from getter of value type object'); # type of data type
is( $Tvalue->ID, 'value',             'got attribute "ID" from getter of value type object');
is( $Tvalue->name, 'value',           'got attribute "name" from getter of value type object');
is( $Tvalue->full_name, 'value',      'got attribute "full_name" from getter of value type object');
is( $Tvalue->help, $vh,               'got attribute "help" from getter of value type object');
is( $Tvalue->code, $vc,               'got attribute "code" from getter of value type object');
is( $Tvalue->parents,  0,             'has no parents');
is( int $Tvalue->has_parent,  0,      'has not any parent');
is( $Tvalue->has_parent(undef), '',   'getter is_parent works on undef input');
ok( $Tvalue->has_parent('') == 0,     'getter is_parent works on empty input');
is( $Tvalue->has_parent('value'), '', 'self is not a parent');
is( $Tvalue->parameter,  '',          'has no parameter');
is( $Tvalue->default_value, '',       'got attribute "default" value from getter');
my $checks = $Tvalue->source;
is( ref $checks, 'ARRAY',             'check pairs are stored in an ARRAY');
is( @$checks, 2,                      'type value has only one check pair ');
is( $checks->[0], $vh,                'check pair key is help string');
is( $checks->[1], $vc,                'check pair value is code string');
my $code = $Tvalue->assemble_source;
my $qmc = quotemeta($vc);
ok( $code =~ /$vh/,                   'code of type checker contains given help string');
ok( $code =~ /$qmc/,                  'code of type checker contains given code string');
my $checker = $Tvalue->checker;
is( ref $checker, 'CODE',             'type checker is a CODE ref');
is( $checker->(3), '',                'checker of type "value", accepts correctly value 3');
ok( $checker->([]),                   'checker of type "value", denies with error correctly ARRAY ref');
is( $Tvalue->check_data(3), '',       'checker method of type "value" accepts correctly value 3');
my $val = [];
ok( $Tvalue->check_data([]),          'checker method of type "value" denies with error correctly ARRAY ref');
is( $Tvalue->check_data($val),
    $checker->($val),                 'got same error message when running checker explicitly or implicitly');

my $state = $Tvalue->state;
is( ref $state, 'HASH',                  'state dump is hash ref');
my $Tvclone = Kephra::Base::Data::Type::Basic->restate($state);
is( ref $Tvclone, $pkg,                  'recreated object for type "value" from serialized state');
is( $Tvclone->ID, 'value',               'got attribute "ID" from getter');
is( $Tvclone->ID_equals( $Tvalue->ID),1, 'ID equals to the one of clone');
is( $Tvclone->name, 'value',          'got attribute "name" from getter');
is( $Tvclone->help, $vh,              'got attribute "help" from getter');
is( $Tvclone->code, $vc,              'got attribute "code" from getter');
is( $Tvclone->parents,   0,      'has no parents');
is( $Tvclone->default_value, '',      'got attribute "default" value from getter');
is( $Tvclone->check_data(3), '',      'check method of type "value" clone accepts correctly value 3');
ok( $Tvclone->check_data([]),         'check method of type "value" clone denies correctly with error an ARRAY ref');
is( $Tvclone->assemble_source(), $code, 'clone still has same code as original');
$checks = $Tvclone->source;
is( ref $checks, 'ARRAY',             'check pairs are stored in an ARRAY');
is( @$checks, 2,                      'type value has only one check pair ');
is( $checks->[0], $vh,                'check pair key is help string');
is( $checks->[1], 'not ref $value',   'check pair value is code string');

my $bc = '$value eq 0 or $value eq 1'; # type bool code
my $Tbool = create_type('bool','0 or 1', $bc, $Tvalue, 0);
is( ref $Tbool, $pkg,                 'created child type object bool');
is( $Tbool->ID, 'bool',               'got attribute "ID" from getter of type bool');
is( $Tbool->ID_equals( $Tvalue->ID),0,'ID not equals to the one of type "value"');
is( $Tbool->name, 'bool',             'got attribute "name" from getter of type bool');
is( $Tbool->help, '0 or 1',           'got attribute "help" from getter of type bool');
is( $Tvalue->has_parent(undef), '',   'has no parents');
is( $Tbool->has_parent,  1,           'type "bool" has parents');

is( $Tbool->has_parent('value'), 1,   'Type "value" is parent of "bool"');
is( $Tbool->default_value, 0,         'got attribute "default" value from getter');
$checks = $Tbool->source;
is( ref $checks, 'ARRAY',             'check pairs are stored in an ARRAY');
is( @$checks, 4,                      'type bool has two check pair ');
is( $checks->[0], $vh,                'first check pair key is inherited help string');
is( $checks->[1], $vc,                'first pair pair value is inherited code string');
is( $checks->[2], '0 or 1',           'second check pair key is help string');
is( $checks->[3], $bc,                'second check pair value is code string');
$checker = $Tbool->checker;
is( ref $checker, 'CODE',             'checker of type "bool" is a CODE ref');
is( $checker->(0), '',                'checker of type "bool" accepts correctly 0');
is( $checker->(1), '',                'checker of type "bool" accepts correctly 1');
ok( $checker->([]),                   'checker of type "bool" denies with error correctly value ARRAY ref');
ok( $checker->(5),                    'checker of type "bool" denies with error correctly value 5');
ok( $checker->('--'),                 'checker of type "bool" denies with error correctly string value --');
is( $Tbool->check_data(0), '',        'check method of type "bool" accepts correctly 0');
is( $Tbool->check_data(1), '',        'check method of type "bool" accepts correctly 1');
ok( $Tbool->check_data([]),           'check method of type "bool" denies with error correctly value ARRAY ref');
ok( $Tbool->check_data(5),            'check method of type "bool" denies with error correctly value 5');
ok( $Tbool->check_data('--'),         'check method of type "bool" denies with error correctly string value --');


my $Tbclone = Kephra::Base::Data::Type::Basic->restate( $Tbool->state );
is( ref $Tbclone, $pkg,              'recreated child type object bool');
is( $Tbclone->name, 'bool',          'got attribute "name" from getter');
is( $Tbclone->parents, 1,            'has one parent');
is( $Tbclone->has_parent,  1,        'type "bool" clone has parents');
is( $Tbclone->has_parent('value'), 1,'type "value" is parent');
is( $Tbclone->default_value, 0,      'got attribute "default" value from getter');
is( $Tbclone->check_data(0), '',     'check method of type "bool" clone accepts correctly 0');
is( $Tbclone->check_data(1), '',     'check method of type "bool" clone accepts correctly 1');
ok( $Tbclone->check_data([]),        'check method of type "bool" clone denies with error correctly value ARRAY ref');
ok( $Tbclone->check_data(5),         'check method of type "bool" clone denies with error correctly value 5');
ok( $Tbclone->check_data('--'),      'check method of type "bool" clone denies with error correctly string value --');

my $str_help = 'character string';
my $Tstr = create_type('str', $str_help, undef, $Tvalue);
is( ref $Tstr, $pkg,                 'created rename type object str with undef help and code');
is( $Tstr->name, 'str',              'got attribute "name" from getter of type str');
is( $Tstr->help, $str_help,          'got attribute "help" from getter of type str');
is( $Tstr->code, 'not ref $value',   '"code" has inherited value');
is( $Tstr->default_value, '',        'got attribute "default" inherited from parent');
is( $Tstr->check_data('-'), '',      'check method of type "str" accepts correctly "-"');
is( $Tstr->check_data(1), '',        'check method of type "str" accepts correctly 1');
ok( $Tstr->check_data([]),           'check method of type "str" denies with error correctly value ARRAY ref');
$checks = $Tstr->source;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 2,                     'type str has one check pair');
is( $checks->[0], $str_help,         'first check pair key is inherited help string');
is( $checks->[1], $vc,               'first pair pair value is inherited code string');
$code = $Tstr->assemble_source;
ok( $code =~ /$str_help/,             'replaces error msg of data checker');
ok( $code =~ /$qmc/,                 'code of type checker contains code string from parent');

$Tstr = create_type('str', 'character string', '', $Tvalue);
is( ref $Tstr, $pkg,                 'created rename type object str with empty help and code');
is( $Tstr->name, 'str',              'got attribute "name" from getter of str');
is( $Tstr->default_value, '',        'inherited default value correctly');
is( $Tstr->check_data('-'), '',      'check method of type "str" accepts correctly "-"');
is( $Tstr->check_data(1), '',        'check method of type "str" accepts correctly 1');
ok( $Tstr->check_data([]),           'check method of type "str" denies with error correctly value ARRAY ref');

$Tbool = create_type({name => 'bool', help => '0 or 1', code => '$value eq 0 or $value eq 1',default => 0, parent => $Tvalue});
is( ref $Tbool, $pkg,                'created type "bool", child of type "value" with argument hash');
is( $Tbool->name, 'bool',            'got attribute "name" from getter of type bool');
is( $Tbool->help, '0 or 1',          'got attribute "help" from getter of type bool');
is( $Tbool->code, '$value eq 0 or $value eq 1',       'got attribute "code" from getter of type bool');
is( int($Tbool->parents), '1',       'got one parent');
is( $Tbool->has_parent('value'), 1,   'Type "value" is parent of "bool"');
is( $Tbool->default_value, 0,        'got attribute "default" value from getter');
is( $Tbool->check_data(0), '',       'check method of type "bool" accepts correctly 0');
is( $Tbool->check_data(1), '',       'check method of type "bool" accepts correctly 1');
ok( $Tbool->check_data([]),          'check method of type "bool" denies with error correctly value ARRAY ref');
ok( $Tbool->check_data(5),           'check method of type "bool" denies with error correctly value 5');
ok( $Tbool->check_data('--'),        'check method of type "bool" denies with error correctly string value "--"');
$checks = $Tbool->source;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 4,                     'type bool has two check pair ');
is( $checks->[0], $vh,               'first check pair key is inherited help string');
is( $checks->[1], $vc,               'first pair pair value is inherited code string');
is( $checks->[2], '0 or 1',          'second check pair key is help string');
is( $checks->[3], $bc,               'second check pair value is code string');


$Tbool = create_type({name => 'bool', help => '0 or 1', code => '$value eq 0 or $value eq 1',default => 0, 
                                      owner => 'sowner', origin => 'sorigin', parent => $Tvalue});
is( ref $Tbool, $pkg,                'created type "bool", with hash definition of parent type "value" in place');
is( $Tbool->kind, 'basic',           'got attribute "kind" from getter of type bool');
is( $Tbool->name, 'bool',            'got attribute "name" from getter of type bool');
is( $Tbool->full_name, 'bool',       'got attribute "full_name" from getter of type bool');
is( int ($Tbool->parents), 1,        'has one parent');
is( $Tbool->has_parent('value'), 1,  'Type "value" is parent of "bool"');
is( $Tbool->default_value, 0,        'got attribute "default" value from getter');
is( $Tbool->check_data(1), '',       'check method of type "bool" accepts correctly 1');
ok( $Tbool->check_data([]),          'check method of type "bool" denies with error correctly value ARRAY ref');
ok( $Tbool->check_data(5),           'check method of type "bool" denies with error correctly value 5');
ok( $Tbool->check_data('--'),        'check method of type "bool" denies with error correctly string value "--"');
$checks = $Tbool->source;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 4,                     'type bool has two check pair ');
is( $checks->[0], $vh,               'first check pair key is inherited help string');
is( $checks->[1], $vc,               'first pair pair value is inherited code string');
is( $checks->[2], '0 or 1',          'second check pair key is help string');
is( $checks->[3], $bc,               'second check pair value is code string');

$Tbool = create_type('bool', '0 or 1', '$value eq 0 or $value eq 1', $Tvalue, 0);
is( ref $Tbool, $pkg,                'created type "bool", with positional definition of parent type "value" in place');
is( $Tbool->name, 'bool',            'got attribute "name" from getter of type bool');
is( $Tbool->help, '0 or 1',          'got attribute "help" from getter of type bool');
is( $Tbool->code, '$value eq 0 or $value eq 1', 'got attribute "code" from getter of type bool');
is( $Tbool->check_data(1), '',       'check method of type "bool" accepts correctly 1');
ok( $Tbool->check_data([]),          'check method of type "bool" denies with error correctly value ARRAY ref');
ok( $Tbool->check_data(5),           'check method of type "bool" denies with error correctly value 5');
ok( $Tbool->check_data('--'),        'check method of type "bool" denies with error correctly string value "--"');
is( $checks->[0], $vh,               'first check pair key is inherited help string');
is( $checks->[1], $vc,               'first pair pair value is inherited code string');

my $Tint = create_type({name => 'int', help => 'integer', code => 'int $value == $value', parent => $Tvalue , default => 0});
my $Tpint = create_type({name => 'int_pos', help => 'positive', code => '$value >= 0', parent => $Tint});
is( int ($Tpint->parents), 2,        'has two parents');
ok( $Tpint->has_parent('value'),     'Type "value" is parent (by direct method)');
ok( $Tpint->has_parent('int'),       'Type "int" is parent (by direct method)');
is( $Tpint->name, 'int_pos',         'got attribute "name" from getter of type pos int');
is( $Tpint->kind, 'basic',           'got attribute "kind" from getter of type pos int');
is( $Tpint->help, 'positive',        'got attribute "help" from getter of type pos int');
is( $Tpint->code, '$value >= 0',     'got attribute "code" from getter of type pos int');


ok( not (ref create_type()),                        'can not create type without any argument');
ok( not (ref create_type(undef, $vh, $vc, '')),     'can not create type without argument "name"');
ok( not (ref create_type('value', undef, $vc, '')), 'can not create type without argument "help"');
ok( not (ref create_type('value', $vh, undef, '')),         'can not create type without argument "code"');
ok( not (ref create_type('value', $vh, 'not ref $value')),  'can not create type without argument "default" value');
ok( not (ref create_type('value', $vh, 'no ref ', undef, '')),  'can not create type without argument functioning "code"');
ok( not (ref create_type('value', $vh, 'not ref $value', undef, [])),  'can not create type without default value adhering type "checks"');
ok( not (ref create_type({})),                      'can not create type with empty hash definition');
ok( not (ref create_type({help => $vh,   code => $vc, default => ''})), 'can not create type with hash ref def without argument "name"');
ok( not (ref create_type({name=>'value', code => $vc, default => ''})), 'can not create type with hash ref def without argument "help"');
ok( not (ref create_type({name=>'value', help => $vh, default => ''})), 'can not create type with hash ref def without argument "code"');
ok( not (ref create_type({name=>'value', help => $vh, code => $vc})),   'can not create type with hash ref def without argument "default" value');
ok( not (ref create_type({name=>'value', help => $vh, code => 'no ref', default => ''})), 'can not create type with hash ref def without functioning "code"');
ok( not (ref create_type({name=>'value', help => $vh, code => $vc, default => []})),       'can not create type without default value adhering type "checks"');


exit 0;

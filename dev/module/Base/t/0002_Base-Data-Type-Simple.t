#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Test::More tests => 100;

use Kephra::Base::Data::Type::Simple;
sub create_type { Kephra::Base::Data::Type::Simple->new(@_) }

my $pkg = 'Kephra::Base::Data::Type::Simple';
my $vh = 'not a reference'; # type value help
my $vc = 'not ref $value'; # type value code
my $Tvalue = create_type('value', $vh, $vc, undef, '');
is( ref $Tvalue, $pkg,               'created first type object "value"');
is( $Tvalue->get_name, 'value',      'got attribute "name" from getter of value type object');
is( $Tvalue->get_default_value, '',  'got attribute "default" value from getter');
my $checks = $Tvalue->get_check_pairs;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 2,                     'type value has only one check pair ');
is( $checks->[0], $vh,               'check pair key is help string');
is( $checks->[1], $vc,               'check pair value is code string');
my $code = $Tvalue->assemble_code;
my $qmc = quotemeta($vc);
ok( $code =~ /$vh/,                  'code of type checker contains given help string');
ok( $code =~ /$qmc/,                 'code of type checker contains given code string');
my $checker = $Tvalue->get_checker;
is( ref $checker, 'CODE',            'type checker is a CODE ref');
is( $checker->(3), '',               'checker of type "value", accepts correctly value 3');
ok( $checker->([]),                  'checker of type "value", denies with error correctly ARRAY ref');
is( $Tvalue->check(3), '',           'checker method of type "value" accepts correctly value 3');
my $val = [];
ok( $Tvalue->check([]),              'checker method of type "value" denies with error correctly ARRAY ref');
is( $Tvalue->check($val),
    $checker->($val),                'got same error message when running checker explicitly or implicitly');

my $state = $Tvalue->state;
is( ref $state, 'HASH',              'state dump is hash ref');
my $Tvclone = Kephra::Base::Data::Type::Simple->restate($state);
is( ref $Tvclone, $pkg,              'recreated object for type "value" from serialized state');
is( $Tvclone->get_name, 'value',     'got attribute "name" from getter');
is( $Tvclone->get_default_value, '', 'got attribute "default" value from getter');
is( $Tvclone->check(3), '',          'check method of type "value" clone accepts correctly value 3');
ok( $Tvclone->check([]),             'check method of type "value" clone denies correctly with error an ARRAY ref');
is( $Tvclone->assemble_code(), $code,'clone still has same code as original');
$checks = $Tvclone->get_check_pairs;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 2,                     'type value has only one check pair ');
is( $checks->[0], $vh,               'check pair key is help string');
is( $checks->[1], 'not ref $value',  'check pair value is code string');

my $bc = '$value eq 0 or $value eq 1'; # type bool code
my $Tbool = create_type('bool','0 or 1', $bc, $Tvalue, 0);
is( ref $Tbool, $pkg,                'created child type object bool');
is( $Tbool->get_name, 'bool',        'got attribute "name" from getter of type bool');
is( $Tbool->get_default_value, 0,    'got attribute "default" value from getter');
$checks = $Tbool->get_check_pairs;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 4,                     'type bool has two check pair ');
is( $checks->[0], $vh,               'first check pair key is inherited help string');
is( $checks->[1], $vc,               'first pair pair value is inherited code string');
is( $checks->[2], '0 or 1',          'second check pair key is help string');
is( $checks->[3], $bc,               'second check pair value is code string');
$checker = $Tbool->get_checker;
is( ref $checker, 'CODE',            'checker of type "bool" is a CODE ref');
is( $checker->(0), '',               'checker of type "bool" accepts correctly 0');
is( $checker->(1), '',               'checker of type "bool" accepts correctly 1');
ok( $checker->([]),                  'checker of type "bool" denies with error correctly value ARRAY ref');
ok( $checker->(5),                   'checker of type "bool" denies with error correctly value 5');
ok( $checker->('--'),                'checker of type "bool" denies with error correctly string value --');
is( $Tbool->check(0), '',            'check method of type "bool" accepts correctly 0');
is( $Tbool->check(1), '',            'check method of type "bool" accepts correctly 1');
ok( $Tbool->check([]),               'check method of type "bool" denies with error correctly value ARRAY ref');
ok( $Tbool->check(5),                'check method of type "bool" denies with error correctly value 5');
ok( $Tbool->check('--'),             'check method of type "bool" denies with error correctly string value --');


my $Tbclone = Kephra::Base::Data::Type::Simple->restate( $Tbool->state );
is( ref $Tbclone, $pkg,              'recreated child type object bool');
is( $Tbclone->get_name, 'bool',      'got attribute "name" from getter');
is( $Tbclone->get_default_value, 0,  'got attribute "default" value from getter');
is( $Tbclone->check(0), '',          'check method of type "bool" clone accepts correctly 0');
is( $Tbclone->check(1), '',          'check method of type "bool" clone accepts correctly 1');
ok( $Tbclone->check([]),             'check method of type "bool" clone denies with error correctly value ARRAY ref');
ok( $Tbclone->check(5),              'check method of type "bool" clone denies with error correctly value 5');
ok( $Tbclone->check('--'),           'check method of type "bool" clone denies with error correctly string value --');

my $Tstr = create_type('str', undef, undef, $Tvalue);
is( ref $Tstr, $pkg,                 'created rename type object str with undef help and code');
is( $Tstr->get_name, 'str',          'got attribute "name" from getter of type str');
is( $Tstr->get_default_value, '',    'inherited default value correctly');
is( $Tstr->check('-'), '',           'check method of type "str" accepts correctly "-"');
is( $Tstr->check(1), '',             'check method of type "str" accepts correctly 1');
ok( $Tstr->check([]),                'check method of type "str" denies with error correctly value ARRAY ref');
$checks = $Tstr->get_check_pairs;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 2,                     'type str has one check pair');
is( $checks->[0], $vh,               'first check pair key is inherited help string');
is( $checks->[1], $vc,               'first pair pair value is inherited code string');
$code = $Tstr->assemble_code;
ok( $code =~ /$vh/,                  'code of type checker contains help string from parent');
ok( $code =~ /$qmc/,                 'code of type checker contains code string from parent');

$Tstr = create_type('str', '', '', $Tvalue);
is( ref $Tstr, $pkg,                 'created rename type object str with empty help and code');
is( $Tstr->get_name, 'str',          'got attribute "name" from getter of str');
is( $Tstr->get_default_value, '',    'inherited default value correctly');
is( $Tstr->check('-'), '',           'check method of type "str" accepts correctly "-"');
is( $Tstr->check(1), '',             'check method of type "str" accepts correctly 1');
ok( $Tstr->check([]),                'check method of type "str" denies with error correctly value ARRAY ref');

$Tbool = create_type({name => 'bool', help => '0 or 1', code => '$value eq 0 or $value eq 1',default => 0, parent => $Tvalue});
is( ref $Tbool, $pkg,                'created type "bool", child of type "value" with argument hash');
is( $Tbool->get_name, 'bool',        'got attribute "name" from getter of type bool');
is( $Tbool->get_default_value, 0,    'got attribute "default" value from getter');
is( $Tbool->check(0), '',            'check method of type "bool" accepts correctly 0');
is( $Tbool->check(1), '',            'check method of type "bool" accepts correctly 1');
ok( $Tbool->check([]),               'check method of type "bool" denies with error correctly value ARRAY ref');
ok( $Tbool->check(5),                'check method of type "bool" denies with error correctly value 5');
ok( $Tbool->check('--'),             'check method of type "bool" denies with error correctly string value "--"');
$checks = $Tbool->get_check_pairs;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 4,                     'type bool has two check pair ');
is( $checks->[0], $vh,               'first check pair key is inherited help string');
is( $checks->[1], $vc,               'first pair pair value is inherited code string');
is( $checks->[2], '0 or 1',          'second check pair key is help string');
is( $checks->[3], $bc,               'second check pair value is code string');


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

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
is( ref $checker, 'CODE',            'checker is a code ref');
is( $checker->(3), '',               'run checker of type "value", has expected positive result');
ok( $checker->([]),                  'run checker of type "value", has expected negative result');
is( $Tvalue->check(3), '',           'run checker of type "value" inside object, has expected positive result');
my $val = [];
ok( $Tvalue->check([]),              'run checker of type "value" inside object, has expected negative result');
is( $Tvalue->check($val),
    $checker->($val),                'got same error message when running checker explicitly or implicitly');

my $state = $Tvalue->state;
is( ref $state, 'HASH',              'state dump is hash ref');
my $Tvclone = Kephra::Base::Data::Type::Simple->restate($state);
is( ref $Tvclone, $pkg,              'recreated object for type "value" from serialized state');
is( $Tvclone->get_name, 'value',     'got attribute "name" from getter');
is( $Tvclone->get_default_value, '', 'got attribute "default" value from getter');
is( $Tvclone->check(3), '',          'checker of type "value" clone has true positive result');
ok( $Tvclone->check([]),             'checker of type "value" clone has true negative result');
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
is( $checker->(0), '',               'checker of type "bool" has true positive result');
is( $checker->(1), '',               'checker of type "bool" has second true positive result');
ok( $checker->([]),                  'checker of type "bool" has true negative result');
ok( $checker->(5),                   'checker of type "bool" has second true negative result');
ok( $checker->('--'),                'checker of type "bool" has third true negative result');
is( $Tbool->check(0), '',            'checker of type "bool" has true positive result');
is( $Tbool->check(1), '',            'checker of type "bool" has second true positive result');
ok( $Tbool->check([]),               'checker of type "bool" has true negative result');
ok( $Tbool->check(5),                'checker of type "bool" has second true negative result');
ok( $Tbool->check('--'),             'checker of type "bool" has third true negative result');


my $Tbclone = Kephra::Base::Data::Type::Simple->restate( $Tbool->state );
is( ref $Tbclone, $pkg,              'recreated child type object bool');
is( $Tbclone->get_name, 'bool',      'got attribute "name" from getter');
is( $Tbclone->get_default_value, 0,  'got attribute "default" value from getter');
is( $Tbclone->check(0), '',          'checker of type "bool" clone has true positive result');
is( $Tbclone->check(1), '',          'checker of type "bool" clone has second true positive result');
ok( $Tbclone->check([]),             'checker of type "bool" clone has true negative result');
ok( $Tbclone->check(5),              'checker of type "bool" clone has second true negative result');
ok( $Tbclone->check('--'),           'checker of type "bool" clone has third true negative result');

my $Tstr = create_type('str', undef, undef, $Tvalue);
is( ref $Tstr, $pkg,                 'created rename type object str with undef help and code');
is( $Tstr->get_name, 'str',          'got attribute "name" from getter of type str');
is( $Tstr->get_default_value, '',    'inherited default value correctly');
is( $Tstr->check('-'), '',           'checker of type "str" has true positive result');
is( $Tstr->check(1), '',             'checker of type "str" has second true positive result');
ok( $Tstr->check([]),                'checker of type "str" has true negative result');
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
is( $Tstr->check('-'), '',           'checker of type "str" has true positive result');
is( $Tstr->check(1), '',             'checker of type "str" has second true positive result');
ok( $Tstr->check([]),                'checker of type "str" has true negative result');

$Tbool = create_type({name => 'bool', help => '0 or 1', code => '$value eq 0 or $value eq 1',default => 0, parent => $Tvalue});
is( ref $Tbool, $pkg,                'created child type object bool with argument hash');
is( $Tbool->get_name, 'bool',        'got attribute "name" from getter of type bool');
is( $Tbool->get_default_value, 0,    'got attribute "default" value from getter');
is( $Tbool->check(0), '',            'checker of type "bool" has true positive result');
is( $Tbool->check(1), '',            'checker of type "bool" has second true positive result');
ok( $Tbool->check([]),               'checker of type "bool" has true negative result');
ok( $Tbool->check(5),                'checker of type "bool" has second true negative result');
ok( $Tbool->check('--'),             'checker of type "bool" has third true negative result');
$checks = $Tbool->get_check_pairs;
is( ref $checks, 'ARRAY',            'check pairs are stored in an ARRAY');
is( @$checks, 4,                     'type bool has two check pair ');
is( $checks->[0], $vh,               'first check pair key is inherited help string');
is( $checks->[1], $vc,               'first pair pair value is inherited code string');
is( $checks->[2], '0 or 1',          'second check pair key is help string');
is( $checks->[3], $bc,               'second check pair value is code string');

ok( create_type({}),                      'can not create type with empty hash definition');
ok( create_type(),                        'can not create type without any argument');
ok( create_type(undef, $vh, $vc, ''),     'can not create type without argument name');
ok( create_type('value', undef, $vc, ''), 'can not create type without argument help');
ok( create_type('value', $vh, undef, ''),         'can not create type without argument code');
ok( create_type('value', $vh, 'not ref $value'),  'can not create type without argument default value');
ok( create_type('value', $vh, 'not ref ', undef, ''),  'can not create type without argument functioning code');
ok( create_type('value', $vh, 'not ref $value', undef, []),  'can not create type without default value adhering type checks');
ok( create_type({help => $vh,   code => $vc, default => ''}), 'can not create type with hash ref def without argument name');
ok( create_type({name=>'value', code => $vc, default => ''}), 'can not create type with hash ref def without argument help');
ok( create_type({name=>'value', help => $vh, default => ''}), 'can not create type with hash ref def without argument code');
ok( create_type({name=>'value', help => $vh, code => $vc}),   'can not create type with hash ref def without argument default value');
ok( create_type({name=>'value', help => $vh, code => 'not ref', default => ''}), 'can not create type with hash ref def without functioning code');
ok( create_type({name=>'value', help => $vh, code => $vc, default => []}),       'can not create type without default value adhering type checks');


exit 0;

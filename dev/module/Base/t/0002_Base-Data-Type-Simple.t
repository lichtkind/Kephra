#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Simple;
use Test::More tests => 100;

my $pkg = 'Kephra::Base::Data::Type::Simple';
my $vh = 'not a reference'; # type value help
my $vc = 'not ref $value'; # type value code
my $value = create_type('value', $vh, $vc, undef, '');
is( ref $value, $pkg,               'created first type object "value"');
is( $value->get_name, 'value',      'remembered type name');
is( $value->get_default_value, '',  'remembered default value');
my $checks = $value->get_check_pairs;
is( ref $checks, 'ARRAY',           'check pairs are stored in an ARRAY');
is( @$checks, 2,                    'type value has only one check pair ');
is( $checks->[0], $vh,              'check pair key is help string');
is( $checks->[1], $vc,              'check pair value is code string');
my $code = $value->assemble_code;
my $qmc = quotemeta($vc);
ok( $code =~ /$vh/,                 'code of type checker contains given help string');
ok( $code =~ /$qmc/,                'code of type checker contains given code string');
my $checker = $value->get_checker;
is( ref $checker, 'CODE',           'checker is a code ref');
is( $checker->(3), '',              'run checker of type "value", has expected positive result');
ok( $checker->([]),                 'run checker of type "value", has expected negative result');
is( $value->check(3), '',           'run checker of type "value" inside object, has expected positive result');
my $val = [];
ok( $value->check([]),              'run checker of type "value" inside object, has expected negative result');
is( $value->check($val),
    $checker->($val),               'got same error message when running checker explicitly or implicitly');

my $state = $value->state;
is( ref $state, 'HASH',              'state dump is hash ref');
my $vclone = Kephra::Base::Data::Type::Simple->restate($state);
is( ref $vclone, $pkg,              'recreated object for type "value"');
is( $vclone->get_name, 'value',     'type name is correct');
is( $vclone->get_default_value, '', 'types default value is correct');
is( $vclone->check(3), '',          'checker of type "value" clone has true positive result');
ok( $vclone->check([]),             'checker of type "value" clone has true negative result');
is( $vclone->assemble_code(), $code,'clone still has same code as original');
$checks = $vclone->get_check_pairs;
is( ref $checks, 'ARRAY',           'check pairs are stored in an ARRAY');
is( @$checks, 2,                    'type value has only one check pair ');
is( $checks->[0], $vh,              'check pair key is help string');
is( $checks->[1], 'not ref $value', 'check pair value is code string');

my $bc = '$value eq 0 or $value eq 1'; # type bool code
my $bool = create_type('bool','0 or 1', $bc, $value, 0);
is( ref $bool, $pkg,               'created child type object bool');
is( $bool->get_name, 'bool',       'remembered type name');
is( $bool->get_default_value, 0,   'remembered default value');
$checks = $bool->get_check_pairs;
is( ref $checks, 'ARRAY',          'check pairs are stored in an ARRAY');
is( @$checks, 4,                   'type bool has two check pair ');
is( $checks->[0], $vh,             'first check pair key is inherited help string');
is( $checks->[1], $vc,             'first pair pair value is inherited code string');
is( $checks->[2], '0 or 1',        'second check pair key is help string');
is( $checks->[3], $bc,             'second check pair value is code string');
$checker = $bool->get_checker;
is( ref $checker, 'CODE',          'checker of type "bool" is a CODE ref');
is( $checker->(0), '',             'checker of type "bool" has true positive result');
is( $checker->(1), '',             'checker of type "bool" has second true positive result');
ok( $checker->([]),                'checker of type "bool" has true negative result');
ok( $checker->(5),                 'checker of type "bool" has second true negative result');
ok( $checker->('--'),              'checker of type "bool" has third true negative result');
is( $bool->check(0), '',           'checker of type "bool" has true positive result');
is( $bool->check(1), '',           'checker of type "bool" has second true positive result');
ok( $bool->check([]),              'checker of type "bool" has true negative result');
ok( $bool->check(5),               'checker of type "bool" has second true negative result');
ok( $bool->check('--'),            'checker of type "bool" has third true negative result');



my $bclone = Kephra::Base::Data::Type::Simple->restate( $bool->state );
is( ref $bclone, $pkg,             'recreated child type object bool');
is( $bclone->get_name, 'bool',     'remembered type name');
is( $bclone->get_default_value, 0, 'remembered default value');
is( $bclone->check(0), '',         'checker of type "bool" clone has true positive result');
is( $bclone->check(1), '',         'checker of type "bool" clone has second true positive result');
ok( $bclone->check([]),            'checker of type "bool" clone has true negative result');
ok( $bclone->check(5),             'checker of type "bool" clone has second true negative result');
ok( $bclone->check('--'),          'checker of type "bool" clone has third true negative result');

my $str = create_type('str', undef, undef, $value);
is( ref $str, $pkg,                'created rename type object str with undef help and code');
is( $str->get_name, 'str',         'remembered type str');
is( $str->get_default_value, '',   'inherited default value correctly');
is( $str->check('-'), '',          'checker of type "str" has true positive result');
is( $str->check(1), '',            'checker of type "str" has second true positive result');
ok( $str->check([]),               'checker of type "str" has true negative result');
$checks = $str->get_check_pairs;
is( ref $checks, 'ARRAY',          'check pairs are stored in an ARRAY');
is( @$checks, 2,                   'type str has one check pair');
is( $checks->[0], $vh,             'first check pair key is inherited help string');
is( $checks->[1], $vc,             'first pair pair value is inherited code string');
$code = $str->assemble_code;
ok( $code =~ /$vh/,                'code of type checker contains help string from parent');
ok( $code =~ /$qmc/,               'code of type checker contains code string from parent');

$str = create_type('str', '', '', $value);
is( ref $str, $pkg,                'created rename type object str with empty help and code');
is( $str->get_name, 'str',         'remembered type str');
is( $str->get_default_value, '',   'inherited default value correctly');
is( $str->check('-'), '',          'checker of type "str" has true positive result');
is( $str->check(1), '',            'checker of type "str" has second true positive result');
ok( $str->check([]),               'checker of type "str" has true negative result');

$bool = create_type({name => 'bool', help => '0 or 1', code => '$value eq 0 or $value eq 1',default => 0, parent => $value});
is( ref $bool, $pkg,               'created child type object bool with argument hash');
is( $bool->get_name, 'bool',       'remembered type name');
is( $bool->get_default_value, 0,   'remembered default value');
is( $bool->check(0), '',           'checker of type "bool" has true positive result');
is( $bool->check(1), '',           'checker of type "bool" has second true positive result');
ok( $bool->check([]),              'checker of type "bool" has true negative result');
ok( $bool->check(5),               'checker of type "bool" has second true negative result');
ok( $bool->check('--'),            'checker of type "bool" has third true negative result');
$checks = $bool->get_check_pairs;
is( ref $checks, 'ARRAY',          'check pairs are stored in an ARRAY');
is( @$checks, 4,                   'type bool has two check pair ');
is( $checks->[0], $vh,             'first check pair key is inherited help string');
is( $checks->[1], $vc,             'first pair pair value is inherited code string');
is( $checks->[2], '0 or 1',        'second check pair key is help string');
is( $checks->[3], $bc,             'second check pair value is code string');

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
ok( create_type({name=>'value', help => $vh, code => $vc, default => []}), 'can not create type without default value adhering type checks');

sub create_type { Kephra::Base::Data::Type::Simple->new(@_) }


exit 0;

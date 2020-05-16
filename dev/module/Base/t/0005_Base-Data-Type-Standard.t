#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}


package TypeTester; 
use Kephra::Base::Data::Type::Standard;    my $bclass  = 'Kephra::Base::Data::Type::Basic';
use Kephra::Base::Data::Type::Parametric;  my $pclass  = 'Kephra::Base::Data::Type::Parametric';
use Kephra::Base::Data::Type::Store;       my $sclass  = 'Kephra::Base::Data::Type::Store';

my $ts = 2 * @Kephra::Base::Data::Type::Standard::basic_types +
         2 * @Kephra::Base::Data::Type::Standard::parametric_types;

#@Kephra::Base::Data::Type::Standard::forbidden_shortcuts;
#%Kephra::Base::Data::Type::Standard::basic_shortcuts;
#%Kephra::Base::Data::Type::Standard::parametric_shortcuts;
#@Kephra::Base::Data::Type::Standard::basic_types;
#@Kephra::Base::Data::Type::Standard::parametric_types;

use Test::More tests => 1;


my $store = Kephra::Base::Data::Type::Store->new();
is( ref $store, $sclass,                                    'could create initial type store object');

for my $type_def (@Kephra::Base::Data::Type::Standard::basic_types){
}

__END__

my @names = Kephra::Base::Data::Type::Standard::list_names();
my @sc = Kephra::Base::Data::Type::Standard::list_shortcuts();
is( int @names, 0,                                                               'no type names to list now');
is( int @sc, 0,                                                                  'no type name shortcuts to list now');
is( Kephra::Base::Data::Type::Standard::is_known('superkalifrailistisch'), 0,    'check for unknown type');
ok( Kephra::Base::Data::Type::Standard::remove('superkalifrailistisch'),         'can not delete unknown type'); 
ok( Kephra::Base::Data::Type::Standard::create_simple( 'value!','not a reference','not ref $value', undef, '' ), 'could not create type with special char in name');
ok( Kephra::Base::Data::Type::Standard::create_simple( 'Value','not a reference','not ref $value', undef, '' ), 'could not create type with upper case char in name');
ok( Kephra::Base::Data::Type::Standard::create_simple( 'va', 'not a reference',  'not ref $value', undef, '' ), 'could not create type with too short name');
ok( Kephra::Base::Data::Type::Standard::create_simple( 'superkalifrailistisch',  'not a reference', 'not ref $value', undef, '' ), 'could not create type with too long name');

my $Tval = Kephra::Base::Data::Type::Standard::create_simple('value',   'defined value', 'defined $value', undef, '');
is( ref $Tval,                                    $sclass,              'created simple data type via method "create_simple"');
is( Kephra::Base::Data::Type::Standard::add($Tval, '$'), '',            'could add the type "value" to the standard');
ok( Kephra::Base::Data::Type::Standard::add($Tval, '$'),                'could not add the type "value" twice to standard');
my $got = Kephra::Base::Data::Type::Standard::get('value');
is( ref $got, $sclass,                                                  'could "get" the added type by name');
is( $got->get_name, 'value',                                            'got the right type');
is( Kephra::Base::Data::Type::Standard::get_shortcut('value'), '$',     'got shortcut from type name "value"');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut('$'), 'value', 'resolve shortcut $ to type name "value"');
is( Kephra::Base::Data::Type::Standard::is_known('value'), 1,           'type "value" is known');
is( Kephra::Base::Data::Type::Standard::is_owned('value'), 1,           'type "value" is owned');
is( Kephra::Base::Data::Type::Standard::is_initial('value'), 0,         'type "value" is not initial (installed by standard lib package)');
is( Kephra::Base::Data::Type::Standard::check_type('value',1), '',      'checked value 1 against type "value" and got correct positive');
is( Kephra::Base::Data::Type::Standard::check_simple('value',[]), '',   'checked ref value against type "value" and got correct positive');
ok( Kephra::Base::Data::Type::Standard::check_type('value',undef),      'checked undef against type "value" and got correct negative');
@names = Kephra::Base::Data::Type::Standard::list_names();
is( int @names, 1,                                                      'can list one type name');
is( $names[0], 'value',                                                 'and name is correct');
@sc = Kephra::Base::Data::Type::Standard::list_shortcuts();
is( @sc, 1,                                                             'there is now one type shortcut to list');
is( $sc[0], '$',                                                        'and name is correct');

my $Tint   = new_type('int',  'integer number', 'int $value eq $value', 'value', 0);
is( ref $Tint,                                    $sclass,              'created simple data type "int" that has parent');
is( Kephra::Base::Data::Type::Standard::is_known('int'), 0,             'type "int" is not known yet');
ok( Kephra::Base::Data::Type::Standard::add($Tint, '$'),                'could add the type "int" to the standard with under shortcut of value');
is( Kephra::Base::Data::Type::Standard::add($Tint, '#'), '',            'could add the type "int" to the standard with own shortcut');
$got = Kephra::Base::Data::Type::Standard::get('int');
is( ref $got, $sclass,                                                  'could "get" the added type by name');
is( $got->get_name, 'int',                                              'got the right type');
is( Kephra::Base::Data::Type::Standard::get_shortcut('int'), '#',       'got shortcut from type name "int"');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut('#'), 'int',   'resolve shortcut to given type name');
is( Kephra::Base::Data::Type::Standard::get_shortcut('value'), '$',     'got shortcut from type name "value"');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut('$'), 'value', 'resolve shortcut $ to type name "value"');
is( Kephra::Base::Data::Type::Standard::is_known('int'), 1,             'type "int" is known');
is( Kephra::Base::Data::Type::Standard::is_owned('int'), 1,             'type "int" is owned');
is( Kephra::Base::Data::Type::Standard::is_initial('int'), 0,           'type "int" is not initial');
is( Kephra::Base::Data::Type::Standard::check_type('int',1), '',        'checked value 1 against type "int" and got correct positive');
ok( Kephra::Base::Data::Type::Standard::check_simple('int',[]),         'checked ref value against type "int" and got correct negative');
ok( Kephra::Base::Data::Type::Standard::check_type('int',undef),        'checked undef against type "int" and got correct negative');
@names = Kephra::Base::Data::Type::Standard::list_names();
is( int @names, 2,                                                      'can list now two type names');
is( $names[0], 'int',                                                   'and name is correct');
@sc = Kephra::Base::Data::Type::Standard::list_shortcuts();
is( @sc, 2,                                                             'there are now two type shortcut to list');
is( $sc[0], '#',                                                        'and name is correct');


package Elsewhere;
Test::More::ok(Kephra::Base::Data::Type::Standard::remove('value'),     'can not remove type owned by different package'); 
Test::More::is( Kephra::Base::Data::Type::Standard::is_owned('value'), 0,'type "value" is not owned by this package');
package TypeTester; 
my $type = Kephra::Base::Data::Type::Standard::remove('value');
is( ref $type,   $sclass,                                               'removed type "value"');
is( $type->get_name,  'value',                                          'removed correct type');
is( Kephra::Base::Data::Type::Standard::is_known('value'), 0,           'type "value" is no longer known');
is( Kephra::Base::Data::Type::Standard::get('value'), undef,            'type "value" can not be given');
is( Kephra::Base::Data::Type::Standard::get_shortcut('value'), undef,   'got shortcut from type name "value" is also no longer known');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut('$'), undef,   'shortcut for type "value" also can not be resolved');
is( Kephra::Base::Data::Type::Standard::is_owned('value'), undef,       'type "value" is not owned because deleted');

is( Kephra::Base::Data::Type::Standard::is_known('int'), 1,             'type "int" is still known');
is( ref Kephra::Base::Data::Type::Standard::get('int'), $sclass,        'type "int" can be fetched');
is( Kephra::Base::Data::Type::Standard::get_shortcut('int'), '#',       'got shortcut from type name "int"');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut('#'), 'int',   'resolve shortcut to given type name');


my $Tpint  = new_type('int_pos', 'positive integer', '$value >= 0', 'int');
my $Tstr   = new_type('str', 'string', 'not ref $value', $Tval, '');
my $Tarray = new_type('array_ref', 'array reference', 'ref $value eq "ARRAY"', undef, []);
my $Thash  = new_type('hash_ref', 'hash reference', 'ref $value eq "HASH"', undef, {});
my $Tw     = new_type('weird', 'improbable type', '$value eq "weird"', undef, 'weird');
is(ref $Tpint, $sclass,                                                  'created simple type by shortcut sub');
Kephra::Base::Data::Type::Standard::add($Tpint, '=');
is (Kephra::Base::Data::Type::Standard::add($Tstr, '~'), '',            'add type with none standard parent');
Kephra::Base::Data::Type::Standard::add($Tarray, '@');
Kephra::Base::Data::Type::Standard::add($Thash, '%');
Kephra::Base::Data::Type::Standard::add($Tw, "'");

my $TindexA = Kephra::Base::Data::Type::Standard::create_param('index', 'valid index of array', {name => 'array', type=> 'array_ref', default=> [1]},
                                                                        'return "value $value is out of range" if $value >= @$param', 'int_pos');
my $TindexH = Kephra::Base::Data::Type::Standard::create_param('index', 'valid index of array', {name => 'hash', type=> 'hash_ref', default=> {'' => 1}},
                                                                        'return "value $value is no valid key" unless exists $param->{$value}', 'str');
is(ref $TindexA, $pclass,                                               'could create parametric type');
is(ref $TindexH, $pclass,                                                   'could create parametric type sibling');
is( Kephra::Base::Data::Type::Standard::add($TindexA, '#'), '',             'could add parametric type' );
is( Kephra::Base::Data::Type::Standard::add($TindexH), '',                  'could add parametric type sibling' );
$got = Kephra::Base::Data::Type::Standard::get('index','array');
is( ref $got, $pclass,                                                          'could "get" the added type by name');
is( $got->get_name, 'index',                                                    'got the right type');
is( $got->get_parameter->get_name, 'array',                                     'even parameter has the right type');
is( Kephra::Base::Data::Type::Standard::get_shortcut('index','param'),'#',      'got shortcut from type "inex of array"');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut('#','param'), 'index', 'resolve shortcut of parametric type "index of array"');
is( Kephra::Base::Data::Type::Standard::get_shortcut('index', 'array'), '#',    'got shortcut from parametric type "index"');
is( Kephra::Base::Data::Type::Standard::get_shortcut('index', 'hash'),  '#',    'got shortcut from parametric type "index" sibling');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut('#','param'), 'index', 'resolve shortcut # to parametric type "index"');
is( Kephra::Base::Data::Type::Standard::is_known('index', 'array'), 1,          'type "index of array" is known');
is( Kephra::Base::Data::Type::Standard::is_known('index', 'hash'), 1,           'type "index of hash" is known');
is( Kephra::Base::Data::Type::Standard::is_owned('index', 'array'), 1,          'type "index of array" is owned');
is( Kephra::Base::Data::Type::Standard::is_owned('index', 'hash'), 1,           'type "index of hash" is owned');
is( Kephra::Base::Data::Type::Standard::is_initial('index', 'array'), 0,        'type "index of array" is not initial');
is( Kephra::Base::Data::Type::Standard::is_initial('index', 'hash'), 0,         'type "index of hash" is not initial');
is( Kephra::Base::Data::Type::Standard::check_param('index', 'array', 2,[1,2,3]),'','checked value 2 and array ref against type "index of array" and got correct positive');
ok( Kephra::Base::Data::Type::Standard::check_param('index', 'array', 2,[1,2]),    'checked value 2 and too small array against type "index of array" and got correct negative');
ok( Kephra::Base::Data::Type::Standard::check_param('index', 'array', 2,{2=>3}),   'checked value 2 and hash against type "index of array" and got correct negative');
ok( Kephra::Base::Data::Type::Standard::check_param('index', 'array', -1,[]),      'checked value -1 against type "index of array" and got correct negative');
is( Kephra::Base::Data::Type::Standard::check_param('index', 'hash', 2,{2=>3}), '','checked value 2 and hash against type "index of hash" and got correct positive');
ok( Kephra::Base::Data::Type::Standard::check_param('index', 'hash', 2,{1=>2}),    'checked value 2 and hash ref against type "index of hash" and got correct negative');
ok( Kephra::Base::Data::Type::Standard::check_param('index', 'hash', 2,[1,2]),     'checked value 2 and array ref against type "index of hash" and got correct negative');
ok( Kephra::Base::Data::Type::Standard::check_param('index', 'hash', [],{''=>2}),  'checked value array ref and hash ref against type "index of hash" and got correct negative');
@names = Kephra::Base::Data::Type::Standard::list_names('param');
is( int @names, 1,                                                              'only one parametric type can be listed');
is( $names[0], 'index',                                                         'listed correct name');
@names = Kephra::Base::Data::Type::Standard::list_names('param','index');
is( int @names, 2,                                                              'parameter of "index" type can be of one of two options');
is( $names[0], 'array',                                                         'one of them is "array"');
is( $names[1], 'hash',                                                          'the other is "hash"');
my $state = Kephra::Base::Data::Type::Standard::state;


ok( Kephra::Base::Data::Type::Standard::remove('a','b'),                'can not "remove" none existing parametric type');
ok( Kephra::Base::Data::Type::Standard::remove('index','c'),            'can not "remove" existing type with none existing parameter');
$type = Kephra::Base::Data::Type::Standard::remove('index', 'hash');
is( ref $type,   $pclass,                                               'removed type "index of hash"');
is( $type->get_name,  'index',                                          'removed correct "index"');
is( $type->get_parameter->get_name,  'hash',                            'removed correct type: "index of hash"');
is( Kephra::Base::Data::Type::Standard::is_known('index', 'hash'),  0,  'type "index of hash" is no longer known');
is( Kephra::Base::Data::Type::Standard::is_known('index', 'array'), 1,  'type "index of array" is still around');
is( Kephra::Base::Data::Type::Standard::is_owned('index', 'array'), 1,  'type "index of array" is owned');
is( Kephra::Base::Data::Type::Standard::is_owned('index', 'hash'),undef,'type "index of hash" is owned');
@names = Kephra::Base::Data::Type::Standard::list_names('param');
is( int @names, 1,                                                      'only one parametric type can be listed');
is( $names[0], 'index',                                                 'listed correct name');
@names = Kephra::Base::Data::Type::Standard::list_names('param','index');
is( int @names, 1,                                                      'parameter of "index" type can be of one option');
is( $names[0], 'array',                                                 'it is "array"');

@names = Kephra::Base::Data::Type::Standard::guess([]);
is( int @names, 1,                                                      'ARRAY ref resulted in one guess');
is( $names[0], 'array_ref',                                             'type "array_ref" could be guessed');
@names = Kephra::Base::Data::Type::Standard::guess(3);
is( int @names, 3,                                                      'int 3 resulted in two guesses');
is( $names[0], 'int',                                                   'int 3 was guessed as "int"');
is( $names[1], 'int_pos',                                               'int 3 was guessed as positive int');
is( $names[2], 'str',                                                   'int 3 was guessed as positive str');
@names = guess_type(-3);
is( int @names, 2,                                                      'int -3 resulted in one guess');
is( $names[0], 'int',                                                   'int -3 was guessed as "int"');
is( $names[1], 'str',                                                   'int -3 was guessed as "str"');

Kephra::Base::Data::Type::Standard::init();
is( Kephra::Base::Data::Type::Standard::is_known('weird'), 1,           '"init" had no effect when called from normal package');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut("'"), 'weird', 'illegal "init" did not delete shortcuts');
Kephra::Base::Data::Type::Standard::restate({});
is( Kephra::Base::Data::Type::Standard::is_known('weird'), 1,           '"restate" had no effect when called from normal package');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut("'"), 'weird', 'illegal "restate" did not delete shortcuts');
is( Kephra::Base::Data::Type::Standard::add($Tval, '$'), '',            'could add again the type "value" to the standard');
is( is_type_known('value'), 1,                                          'type value is there, (checked by shortcut sub)');

package Kephra::Base::Data::Type; 
Kephra::Base::Data::Type::Standard::restate($state);
package TypeTester; 
@names = Kephra::Base::Data::Type::Standard::list_names('param');
is( int @names, 1,                                                      'only one parametric type can be listed');
is( $names[0], 'index',                                                 'listed correct name');
@names = Kephra::Base::Data::Type::Standard::list_names('param','index');
is( int @names, 2,                                                      'after  restate parameter of "index" can be again of one of two options');
is( $names[0], 'array',                                                 'one of them is "array"');
is( $names[1], 'hash',                                                  'the other is "hash"');
is( Kephra::Base::Data::Type::Standard::is_known('value'), 0,           '"restate" deleted type "value" again');


Kephra::Base::Data::Type::Standard::init();
is( Kephra::Base::Data::Type::Standard::is_known('weird'), 1,           'type "weird" is still there because "init" from random package is illegal');
package Kephra::Base::Data::Type; 
Kephra::Base::Data::Type::Standard::init();
package TypeTester; 
is( Kephra::Base::Data::Type::Standard::is_known('value'), 1,           'after "init" the initial type "value" is known');
is( Kephra::Base::Data::Type::Standard::is_known('weird'), 0,           '"init" deleted "weird" type');
is( Kephra::Base::Data::Type::Standard::resolve_shortcut("'"), undef,   '"init" also deleted "weird" shortcut');



is( 'num' ~~ [guess_type(2.3)],         1, 'sub guess_type got imported');
is( check_type('value',1),             '', 'recognize 1 as value');
is( check_type('value','1'),           '', 'even "1" is a value');
is( check_type('value',0),             '', 'recognize 0 as value');
is( check_type('value',''),            '', 'recognize empty string as value');
is( check_type('value','d'),           '', 'recognize letter value');
is( check_type('value',[]),            '', 'recognize that ref is a value');
ok( check_type('value',undef),             'only undef is not a value');

is( check_type('no_ref', 1),           '', 'recognize 1 as value');
is( check_type('no_ref', 2.3E2),       '', 'recognize sci real as value');
is( check_type('no_ref', 0),           '', 'recognize 0 as value');
is( check_type('no_ref', 'd'),         '', 'recognize string as value');
is( check_type('no_ref', ''),          '', 'recognize empty string as value');
ok( check_type('no_ref',[]),               'ARRAY is a ref');
ok( check_type('no_ref',{}),               'HASH is a ref');
ok( check_type('no_ref',sub {}),           'CODE is a ref');
ok( check_type('no_ref',qr//),             'Regex is a ref');

is( check_type('bool',1),              '', 'recognize boolean value true');
is( check_type('bool',0),              '', 'recognize boolean value false');
ok( check_type('bool',''),                 'empty is not boolean');
ok( check_type('bool','der'),              'string is not boolean');
ok( check_type('bool',2),                  'int is not boolean');
ok( check_type('bool',2.3),                'float is not boolean');
ok( check_type('bool',[]),                 'ref is not boolean');
is( Kephra::Base::Data::Type::Standard::get('bool')->get_default_value(), 0, 'got default bool');

is( check_type('num',22),              '', 'recognize an integer as a number');
is( check_type('num',1.5),             '', 'recognize small float as number');
is( check_type('num',0.1e-5),          '', 'recognize scientific number');
is( check_type('num',1000_00),         '', 'recognize underscore seperated number');
ok( check_type('num','das'),               'string is not a number');
ok( check_type('num', sub{}),              'coderef is not a number');
is( Kephra::Base::Data::Type::Standard::get('num')->get_default_value(), 0, 'got default number');

is( check_type('num_pos',1.5),         '', 'recognize positive number');
is( check_type('num_pos',0),           '', 'zero is positive number');
ok( check_type('num_pos',-1.5),            'a negative is not a positive number');
ok( check_type('num_pos','das'),           'string is not a positive number');

is( check_type('int',  5),             '', 'recognize integer');
is( check_type('int',-12),             '', 'recognize negative integer');
is( check_type('int',1_2e12),          '', 'recognize huge integer');
ok( check_type('int',1.5),                 'real is not an integer');
ok( check_type('int','das'),               'string is not an integer');
ok( check_type('int',{}),                  'hash ref is not an integer');

is( check_type('int_pos',1),           '', 'recognize positive int');
is( check_type('int_pos',0),           '', 'zero is positive int');
ok( check_type('int_pos',-1),              'a negative is not a positive int');
ok( check_type('int_pos','das'),           'string is not a positive int');

is( check_type('int_spos',1),          '', 'one is a stricly positive number');
ok( check_type('int_spos',0),              'zero is not a stricly positive number');

is( check_type('str', 'das'),          '', 'recognize string');
is( check_type('str', 5),              '', 'numbers can be strings');
ok( check_type('str', {}),                 'ref ist not a string');


is( check_type('str_ne','das'),        '', 'recognize none empty string');
ok( check_type('str_ne', ''),              'this is not a none empty string');

is( check_type('str_uc', 'DAS'),       '', 'recognize upper case string');
ok( check_type('str_uc', 'DaS'),           'this is not an upper case string');
is( Kephra::Base::Data::Type::Standard::get('str_uc')->get_default_value(), 'A', 'got default upper case string');

is( check_type('str_lc', 'das'),       '', 'recognize lower case string');
ok( check_type('str_lc', 'DaS'),           'this is not an lower case string');

is( check_type('num',  1.5),           '', 'recognize number');
is( check_type('num_pos', 1.5),        '', 'recognize positive number');
is( check_type('int',     5),          '', 'recognize integer');
is( check_type('int_pos', 5),          '', 'recognize positive integer');


my @type = guess_type(5);
ok( !('bool' ~~ \@type),  '5 is not an boolean');
ok( 'int' ~~ \@type,      '5 is an integer');
ok( 'int_pos' ~~ \@type,  '5 is a positive integer');
ok( 'int_spos' ~~ \@type, '5 is a strictly positive integer');
ok( 'num' ~~ \@type,      '5 is a number');
ok( 'num_pos' ~~ \@type,  '5 is a positive number');
ok( 'str_ne' ~~ \@type,   '5 is none empty string');
ok( 'any' ~~ \@type,      '5 is anything');


@type = guess_type(0);
ok( 'bool' ~~ \@type,     '0 is a boolean');
ok( 'int' ~~ \@type,      '0 is an integer');
ok( 'int_pos' ~~ \@type,  '0 is a positive integer');
ok( 'num' ~~ \@type,      '0 is a number');
ok( 'num_pos' ~~ \@type,  '0 is a positive number');
ok( 'str_ne' ~~ \@type,   '0 is none empty string');
ok( 'any' ~~ \@type,      '0 is a value');

@type = guess_type('');
ok( !('bool' ~~ \@type),  'empty string is not a boolean');
ok( !('int' ~~ \@type),   'empty string is not an integer');
ok( !('num' ~~ \@type),   'empty string is not a number');
ok( !('str_ne' ~~ \@type),'not empty string');
ok( 'any' ~~ \@type,      'empty string is a value');

@type = Kephra::Base::Data::Type::Standard::list_names();
ok( ('bool' ~~ \@type),  'bool type is known, list works');
ok( ('num' ~~ \@type),   'num type is known, list works');
ok( ('int' ~~ \@type),   'int type is known, list works');
ok( ('any' ~~ \@type),   'any type is known, list works');


exit 0;


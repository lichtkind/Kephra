#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

package Very::Long::Package; sub new {bless {}} 

use Test::More tests => 200;

my $btclass = 'Kephra::Base::Data::Type::Basic';
my $ptclass = 'Kephra::Base::Data::Type::Parametric';

sub simple_type { Kephra::Base::Data::Type::Basic->new(@_) }
sub para_type { Kephra::Base::Data::Type::Parametric->new(@_) }

eval "use $ptclass";
is( $@, '', 'could load the module '.$ptclass);

my $erefdef = [];
my $crefdef = [1];
my $Tany   = simple_type('any', 'anything', '1', undef, '1');
my $Tval   = simple_type('value', 'not a reference', 'not ref $value', undef, '', 'sowner', 'sorigin');
my $Tstr   = simple_type('str', 'character string', undef, $Tval );
my $Tint   = simple_type('int', 'integer number', 'int $value eq $value', $Tval, 0 );
my $Tpint  = simple_type('pos_int', 'positive integer', '$value >= 0', $Tint);
my $Tarray = simple_type('array', 'array reference', 'ref $value eq "ARRAY"', undef, $crefdef);
my $Ttype  = simple_type('array', 'array reference', 'ref $value eq "ARRAY"', $Tstr, 'ANY');

my $Tindex = para_type('index', 'valid index of array', 'return "value $value is out of range" if $value >= @$param',
                       simple_type( {name => 'parray', help => 'dummy basic array type', parent => $Tarray}),    # inherit both defaults
                       $Tpint, 0, 'powner', 'porigin');
my $Tref = para_type({name => 'reference', help => 'reference of given type', 
                      parameter => simple_type( {name => 'refname', help => 'name of areference', parent => $Tstr, default => 'ARRAY'}), 
                      code => 'return "value $value is not a $param reference" if ref $value ne $param', default => $erefdef, parent => $Tany, }); # overwrite both defaults
my $Tshortref = para_type({name => 'short_ref', help => 'reference with short, given name',  
                     code => 'return "reference $param is too long " if length $param > 9', parent => $Tref,}); # 

is ( ref $Tindex, $ptclass,                    'created first prametric type object, type "index" with positional arguments');
is ( $Tindex->kind, 'param',                   'got attribute "kind" from getter of "index"');
is ( $Tindex->name, 'index',                   'got attribute "name" from getter of "index"');
is ( $Tindex->full_name, 'index of parray',    'got full name of type "index of parray"');
is ( $Tindex->help, 'valid index of array',    'got attribute "help" from getter of "index"');
is ( $Tindex->default_value, 0,                'got attribute "default" value from getter of "index"');
is( int ($Tindex->parents), 3,                 'has three parents');
is( $Tindex->has_parent(), 1,                  'param type "index" has parents');
ok( $Tindex->has_parent('value'),              'Type "value" is parent');
ok( $Tindex->has_parent('int'),                'Type "int" is parent');
ok( $Tindex->has_parent('pos_int'),            'Type "pos_int" is parent');
is( ref $Tindex->ID,  'ARRAY',                 'parametric type has complex ID');
is( $Tindex->ID->[0], 'index',                 'contains type name');
is( $Tindex->ID->[1], 'parray',                'and parameter name');

my $param = $Tindex->parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "index"');
is ( $param->name, 'parray',                    'got attribute "name" from "index" parameter');
is ( $param->default_value, $crefdef,          'got attribute "default" from "index" parameter');
my $checker = $Tindex->checker;
my $tchecker = $Tindex->trusting_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->(0,[1,2,3]), '',                'checker of type "index" accepts correctly min index 0');
is ( $checker->(2,[1,2,3]), '',                'checker of type "index" accepts correctly max index 2');
ok ( $checker->(-1,[1,2,3]),                   'checker of type "index" denies with error correctly negative index');
ok ( $checker->(3,[1,2,3]),                    'checker of type "index" denies with error correctly too large index');
ok ( $checker->('-',[1,2,3]),                  'checker of type "index" denies with error correctly none number index');
ok ( $checker->([],[1,2,3]),                   'checker of type "index" denies with error correctly none value index');
ok ( $checker->(0,{1=>2}),                     'checker of type "index" denies with error correctly none ARRAY parameter');
is ( ref $tchecker, 'CODE',                    'attribute "trusting checker" is a CODE ref');
is ( $tchecker->(0,[1,2,3]), '',               'trusting checker of type "index" accepts correctly min index 0');
is ( $tchecker->(2,[1,2,3]), '',               'trusting checker of type "index" accepts correctly max index 2');
ok ( $tchecker->(-1,[1,2,3]),                  'trusting checker of type "index" denies with error correctly negative index');
ok ( $tchecker->(3,[1,2,3]),                   'trusting checker of type "index" denies with error correctly too large index');
ok ( $tchecker->('-',[1,2,3]),                 'trusting checker of type "index" denies with error correctly none number index');
ok ( $tchecker->([],[1,2,3]),                  'trusting checker of type "index" denies with error correctly none value index');
is ( $Tindex->check_data(0,[1,2,3]), '',       'check method of type "index" accepts correctly min index 0');
is ( $Tindex->check_data(2,[1,2,3]), '',       'check method of type "index" accepts correctly max index 2');
ok ( $Tindex->check_data(-1,[1,2,3]),          'check method of type "index" denies with error correctly negative index');
ok ( $Tindex->check_data(3,[1,2,3]),           'check method of type "index" denies with error correctly too large index');
ok ( $Tindex->check_data('-',[1,2,3]),         'check method of type "index" denies with error correctly none number index');
ok ( $Tindex->check_data([],[1,2,3]),          'check method of type "index" denies with error correctly none value index');
ok ( $Tindex->check_data(0,{1=>2}),            'check method of type "index" denies with error correctly none ARRAY parameter');

my $state = $Tindex->state;
is ( ref $state, 'HASH',                       'state of "index" type is a HASH ref');
is ( ref $state->{'parameter'}, 'HASH',        'state of "index" type parameter is a HASH ref');
is ( $state->{'name'},          'index',       '"name" in type "index" state HASH is correct');
is ( $state->{'parameter'}{'name'}, 'parray',  'parameter "name" in type "index" state is correct');
my $Ticlone = Kephra::Base::Data::Type::Parametric->restate($state);
is ( ref $Ticlone, $ptclass,                   'recreated first prametric type object, type "index" by restate from dumped state');
is ( $Ticlone->kind, 'param',                  'got attribute "ID" from getter of "index" clone');
is ( $Ticlone->name, 'index',                  'got attribute "name" from getter of "index" clone');
is ( $Ticlone->ID_equals($Tindex->ID), 1,      'cloning should not change ID');
is ( $Ticlone->ID_equals($Tindex->parameter->ID), 0,      'parameter should have different ID');
ok( $Ticlone->has_parent('pos_int'),           'Type "pos_int" is parent');
ok( $Ticlone->has_parent('int'),               'Type "int" is parent');
is ( $Ticlone->help,'valid index of array',    'got attribute "help" from getter of "index" clone');
is ( $Ticlone->default_value, 0,               'got attribute "default" value from getter of "index" clone');
$param = $Ticlone->parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "index" clone');
is ( $param->name, 'parray',                   'got attribute "name" from "index" clone parameter');
is ( $param->default_value, $crefdef,          'got attribute "default" from "index" clone parameter');
$checker = $Ticlone->checker;
$tchecker = $Ticlone->trusting_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->(0,[1,2,3]), '',                'checker of type "index" clone accepts correctly min index 0');
is ( $checker->(2,[1,2,3]), '',                'checker of type "index" clone accepts correctly max index 2');
ok ( $checker->(-1,[1,2,3]),                   'checker of type "index" clone denies with error correctly negative index');
ok ( $checker->(3,[1,2,3]),                    'checker of type "index" clone denies with error correctly too large index');
ok ( $checker->('-',[1,2,3]),                  'checker of type "index" clone denies with error correctly none number index');
ok ( $checker->([],[1,2,3]),                   'checker of type "index" clone denies with error correctly none value index');
ok ( $checker->(0,{1=>2}),                     'checker of type "index" clone denies with error correctly none ARRAY parameter');
is ( ref $tchecker, 'CODE',                    'attribute "trusting checker" is a CODE ref');
is ( $tchecker->(0,[1,2,3]), '',               'trusting checker of type "index" clone accepts correctly min index 0');
is ( $tchecker->(2,[1,2,3]), '',               'trusting checker of type "index" clone accepts correctly max index 2');
ok ( $tchecker->(-1,[1,2,3]),                  'trusting checker of type "index" clone denies with error correctly negative index');
ok ( $tchecker->(3,[1,2,3]),                   'trusting checker of type "index" clone denies with error correctly too large index');
ok ( $tchecker->('-',[1,2,3]),                 'trusting checker of type "index" clone denies with error correctly none number index');
ok ( $tchecker->([],[1,2,3]),                  'trusting checker of type "index" clone denies with error correctly none value index');
is ( $Ticlone->check_data(0,[1,2,3]), '',      'check method of type "index" clone accepts correctly min index 0');
is ( $Ticlone->check_data(2,[1,2,3]), '',      'check method of type "index" clone accepts correctly max index 2');
ok ( $Ticlone->check_data(-1,[1,2,3]),         'check method of type "index" clone denies with error correctly negative index');
ok ( $Tindex->check_data('-',[1,2,3]),         'check method of type "index" clone denies with error correctly none number index');
ok ( $Tindex->check_data([],[1,2,3]),          'check method of type "index" clone denies with error correctly none value index');
ok ( $Tindex->check_data(0,{1=>2}),            'check method of type "index" clone denies with error correctly none ARRAY parameter');

$Tindex = para_type('index', 'valid index of array', 'return "value $value is out of range" if $value >= @$param', $Tarray, $Tpint);
is ( ref $Tindex, $ptclass,                    'created first prametric type "index" with type object as parameter');
is ( $Tindex->name, 'index',                   'got attribute "name" from getter of "index"');
is ( $Tindex->help, 'valid index of array',    'got attribute "help" from getter of "index"');
is ( $Tindex->default_value, 0,                'got attribute "default" value from getter of "index"');
ok( $Tindex->has_parent('pos_int'),            'Type "pos_int" is parent');
$param = $Tindex->parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "index"');
is ( $param->name, 'array',                    'got attribute "name" from "index" parameter');
is ( $param->default_value, $crefdef,          'got attribute "default" from "index" parameter');
$checker = $Tindex->checker;
$tchecker = $Tindex->trusting_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->(0,[1,2,3]), '',                'checker of type "index" accepts correctly min index 0');
is ( $checker->(2,[1,2,3]), '',                'checker of type "index" accepts correctly max index 2');
ok ( $checker->(-1,[1,2,3]),                   'checker of type "index" denies with error correctly negative index');
ok ( $checker->(3,[1,2,3]),                    'checker of type "index" denies with error correctly too large index');
is ( $tchecker->(0,[1,2,3]), '',               'trusting checker of type "index" clone accepts correctly min index 0');
is ( $tchecker->(2,[1,2,3]), '',               'trusting checker of type "index" clone accepts correctly max index 2');
ok ( $tchecker->(-1,[1,2,3]),                  'trusting checker of type "index" clone denies with error correctly negative index');
ok ( $tchecker->(3,[1,2,3]),                   'trusting checker of type "index" clone denies with error correctly too large index');

is ( ref $Tref, $ptclass,                      'created second prametric type object, type "ref" with named arguments');
is ( $Tref->name, 'reference',                 'got attribute "name" from getter of type "ref"');
is ( $Tref->full_name, 'reference of refname', 'got full name of type "reference of refname"');
is ( $Tref->help,'reference of given type',    'got attribute "help" from getter of type "ref"');
is ( $Tref->default_value, $erefdef,           'got attribute "default" value from getter of "ref"');
is ( $Tref->has_parent(), 1,                   'param type "reference" has parents');
ok( $Tref->has_parent('any'),                  'Type "any" is parent');
$param = $Tref->parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "ref"');
is ( $param->name, 'refname',                  'got attribute "name" from "ref" parameter');
is ( $param->default_value, 'ARRAY',           'got attribute "default" from "ref" parameter');
$checker = $Tref->checker;
$tchecker = $Tref->trusting_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->( {}, 'HASH'), '',              'checker of type "ref" accepts correctly HASH ref');
is ( $checker->( sub {}, 'CODE'), '',          'checker of type "ref" accepts correctly CODE ref');
is ( $checker->( $Tref, $ptclass), '',         'checker of type "ref" accepts correctly own ref');
is ( $checker->(1, ''), '',                    'checker of type "ref" accepts correctly none ref');
ok ( $checker->([],'Regex'),                   'checker of type "ref" denies with error correctly ARRAY ref as not a Regex ref');
ok ( $checker->([],[]),                        'checker of type "ref" denies with error correctly when parameter is not a str');
is ( ref $tchecker, 'CODE',                    'attribute "trusting checker" is a CODE ref');
is ( $tchecker->( {}, 'HASH'), '',             'trusting checker of type "ref" accepts correctly HASH ref');
is ( $tchecker->( sub {}, 'CODE'), '',         'trusting checker of type "ref" accepts correctly CODE ref');
is ( $tchecker->( $Tref, $ptclass), '',        'trusting checker of type "ref" accepts correctly own ref');
is ( $tchecker->(1, ''), '',                   'trusting checker of type "ref" accepts correctly none ref');
ok ( $tchecker->([],'Regex'),                  'trusting checker of type "ref" denies with error correctly ARRAY ref as not a Regex ref');
is ( $Tref->check_data( {}, 'HASH'), '',       'check method of type "ref" accepts correctly HASH ref');
is ( $Tref->check_data( sub {}, 'CODE'), '',   'check method of type "ref" accepts correctly CODE ref');
is ( $Tref->check_data( $Tref, $ptclass), '',  'check method of type "ref" accepts correctly own ref');
is ( $Tref->check_data(1, ''), '',             'check method of type "ref" accepts correctly none ref');
ok ( $Tref->check_data([],'Regex'),            'check method of type "ref" denies with error correctly ARRAY ref as not a Regex ref');
ok ( $Tref->check_data([],[]),                 'check method of type "ref" denies with error correctly when parameter is not a str');

$state = $Tref->state;
is ( ref $state, 'HASH',                       'state of "ref" type is a HASH ref');
is ( ref $state->{'parameter'}, 'HASH',        'state of "ref" type parameter is a HASH ref');
is ( $state->{'name'},          'reference',   '"name" in type "ref" state HASH is correct');
is ( $state->{'parameter'}{'name'}, 'refname', 'parameter "name" in type "ref" state is correct');
my $Trefclone = Kephra::Base::Data::Type::Parametric->restate($state);
is ( ref $Trefclone, $ptclass,                 'recreated prametric type object, "ref" by restate from dumped state');
is ( $Trefclone->name, 'reference',            'got attribute "name" from getter of "ref" clone');
is ( $Trefclone->help, 'reference of given type','got attribute "help" from getter of "ref" clone');
is ( $Trefclone->default_value, $erefdef,      'got attribute "default" value from getter of "ref"');
ok( $Trefclone->has_parent('any'),              'Type "any" is parent');
$param = $Trefclone->parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "ref" clone');
is ( $param->name, 'refname',                  'got attribute "name" from "ref" clone parameter');
is ( $param->default_value, 'ARRAY',           'got attribute "default" from "ref" clone parameter');
$checker = $Trefclone->checker;
$tchecker = $Trefclone->trusting_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->( {}, 'HASH'), '',              'checker of type "ref" clone accepts correctly HASH ref');
is ( $checker->( sub {}, 'CODE'), '',          'checker of type "ref" clone accepts correctly CODE ref');
is ( $checker->( $Tref, $ptclass), '',         'checker of type "ref" clone accepts correctly own ref');
is ( $checker->(1, ''), '',                    'checker of type "ref" clone accepts correctly none ref');
ok ( $checker->([],'Regex'),                   'checker of type "ref" clone denies with error correctly ARRAY ref as not a Regex ref');
ok ( $checker->([],[]),                        'checker of type "ref" clone denies with error correctly when parameter is not a str');
is ( ref $tchecker, 'CODE',                    'attribute "trusting checker" is a CODE ref');
is ( $tchecker->( {}, 'HASH'), '',             'trusting checker of type "ref" clone accepts correctly HASH ref');
is ( $tchecker->( sub {}, 'CODE'), '',         'trusting checker of type "ref" clone accepts correctly CODE ref');
is ( $tchecker->( $Tref, $ptclass), '',        'trusting checker of type "ref" clone accepts correctly own ref');
is ( $tchecker->(1, ''), '',                   'trusting checker of type "ref" clone accepts correctly none ref');
ok ( $tchecker->([],'Regex'),                  'trusting checker of type "ref" clone denies with error correctly ARRAY ref as not a Regex ref');
is ( $Trefclone->check_data( {}, 'HASH'), '',       'check method of type "ref" clone accepts correctly HASH ref');
is ( $Trefclone->check_data( sub {}, 'CODE'), '',   'check method of type "ref" clone accepts correctly CODE ref');
is ( $Trefclone->check_data( $Tref, $ptclass), '',  'check method of type "ref" clone accepts correctly own ref');
is ( $Trefclone->check_data(1, ''), '',             'check method of type "ref" clone accepts correctly none ref');
ok ( $Trefclone->check_data([],'Regex'),            'check method of type "ref" clone denies with error correctly ARRAY ref as not a Regex ref');
ok ( $Trefclone->check_data([],[]),                 'check method of type "ref" clone denies with error correctly when parameter is not a str');

is ( ref $Tshortref, $ptclass,                      'created prametric type that inherits from another param type');
is ( $Tshortref->kind, 'param',                     'got attribute "name" from getter of type "short_ref"');
is ( $Tshortref->name, 'short_ref',                 'got attribute "name" from getter of type "short_ref"');
is ( ref $Tshortref->ID, 'ARRAY',                   'ID of parametric type is ARRAY with name and param name');
is ( $Tshortref->ID->[0], 'short_ref',              'found type name in ID');
is ( $Tshortref->ID->[1], 'refname',                'found param name in ID');
is ( $Tshortref->help,'reference with short, given name', 'got attribute "help" from getter of type "short_ref"');
is ( $Tshortref->default_value, $erefdef,           'got attribute "default" value from getter of "short_ref" (was inherited properly)');
ok( $Tshortref->has_parent('any'),                  'Type "ANY" is parent');
ok( $Tshortref->has_parent(['reference','refname']),'Type "reference" of "refname" is parent');
is( $Tshortref->parameter->name, 'refname',         'access to parameter object works' );
ok( $Tshortref->parameter->has_parent('str'),       'parameter Type parent is recognized as parent' );
ok( !$Tshortref->parameter->has_parent('summy'),    'random type name is not a parent of parameter type' );

$param = $Tshortref->parameter();
is ( ref $param, $btclass,                          'got attribute "parameter" object from getter of "short_ref" (was inherited properly)');
is ( $param->name, 'refname',                       'got attribute "name" from "short_ref" parameter');
is ( $param->default_value, 'ARRAY',                'got attribute "default" from "short_ref" parameter (was inherited properly)');
$checker = $Tshortref->checker;
$tchecker = $Tshortref->trusting_checker;
is ( ref $checker, 'CODE',                          'attribute "checker" of "short_ref" type is a CODE ref');
is ( $checker->( {}, 'HASH'), '',                   'checker of type "short_ref" clone accepts correctly HASH ref');
ok ( $checker->( [], 'HASH'),                       'checker of type "short_ref" bad ref type correctly');
ok ( $checker->( Very::Long::Package->new(), 'Very::Long::Package'),  'checker of type "short_ref" denied too long ref name correctly');
is ( ref $tchecker, 'CODE',                         'attribute "trusting checker" of "short_ref" type is a CODE ref');
is ( $tchecker->( {}, 'HASH'), '',                  'trusting checker of type "short_ref" clone accepts correctly HASH ref');
ok ( $tchecker->( [], 'HASH'),                      'trusting checker of type "short_ref" bad ref type correctly');
ok ( $tchecker->( Very::Long::Package->new(), 'Very::Long::Package'),  'trusting  checker of type "short_ref" denied too long ref name correctly');


para_type({name => 'short_ref', help => 'reference with short, given name',  
                 code => 'return "reference $param is too long " if length $param > 9',             parent => $Tref}); # 
my $para = {name => 'array', type => $Tarray, default => $crefdef};
my $kode = 'return "value $value is out of range" if $value >= @$param';
ok( not( ref para_type()),                                                      'can not create type without any argument');
ok( not( ref para_type(undef,'valid index of array', $para, $kode, $Tpint)),    'can not create type without argument "name"');
ok( not( ref para_type('index', undef, $para, $kode, $Tpint, 0)),               'can not create type without argument "help"');
ok( not( ref para_type('index', 'valid index of array', undef, $kode, $Tpint)), 'can not create type without argument "parameter"');
ok( not( ref para_type('index', 'valid index of array', $para, undef, $Tpint)), 'can not create type without argument "code"');
ok( not( ref para_type('index', 'valid index of array', $para, $kode, undef)),  'can not create type without argument "parent"');
ok( not( ref para_type('index', 'valid index of array', {}, $kode, $Tpint)),    'can not create type with empty "parameter" definition');
ok( para_type('index', 'valid index of array', {parent => $Tarray}, $kode, $Tpint), '"parameter" definition with just a type to inherit from name and default is not good');
ok( not( ref para_type('index', 'valid index of array', {parent => $Tarray, default => {}}, $kode, $Tpint)), '"parameter" default value has to adhere type constrains');
ok( not( ref para_type('index', 'valid index of array', $para, 'rerun', $Tpint)),   'can not create type with "code" that can not eval');
ok( not( ref para_type('index', 'valid index of array', $para, $kode, $Tpint, -5)), 'can not create type with "default" that is outside type constrains');

ok( not( ref para_type({})),                                                                                      'can not create param type with empty HASH definition');
ok( not( ref para_type({help => 'valid index of array', parameter => $para, code => $kode, parent => $Tpint})),   'can not create type without named argument "name"');
ok( not( ref para_type({name => 'index', parameter => $para, code => $kode, parent => $Tpint})),                  'can not create type without named argument "help"');
ok( not( ref para_type({name => 'index', help => 'valid index of array', code => $kode, parent => $Tpint})),      'can not create type without argument "parameter"');
ok( not( ref para_type({name => 'index', help => 'valid index of array', parameter => {}, code => $kode, parent => $Tpint})), 'can not create type with empty "parameter" definition');
ok( not( ref para_type({name => 'index', help => 'valid index of array', parameter => {parent => $Tarray, default=>{}}, code => $kode, parent => $Tpint})),
                                                                                                                  '"parameter" default value has to adhere type constrains');
ok( para_type({name => 'index', help => 'valid index of array', parameter => {parent => $Tarray}, code => $kode, parent => $Tpint}),
                                                                                                                  'named "parameter" definition with just a type to inherit from name and default is not good');
ok( not( ref para_type({name => 'index', help => 'valid index of array', parameter => $para, parent => $Tpint})), 'can not create type without argument "code"');
ok( not( ref para_type({name => 'index', help => 'valid index of array', parameter => $para, code => 'rerun', parent => $Tpint})), 'can not create type without "code" that can eval');
ok( not( ref para_type({name => 'index', help => 'valid index of array', parameter => $para, code => $kode})),     'can not create type without argument "parent"');
ok( not( ref para_type({name => 'index', help => 'valid index of array', parameter => $para, code => $kode, parent => $Tpint, default => -5})),
                                                                                                                   'can not create type with "default" that is outside type constrains');

exit 0;

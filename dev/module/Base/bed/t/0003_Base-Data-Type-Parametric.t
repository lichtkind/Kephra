#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

package Very::Long::Package; sub new {bless {}} 

use Kephra::Base::Data::Type::Parametric;
use Test::More tests => 170;

sub simple_type { Kephra::Base::Data::Type::Basic->new(@_) }
sub para_type { Kephra::Base::Data::Type::Parametric->new(@_) }

my $erefdef = [];
my $crefdef = [1];
my $Tany   = simple_type('ANY', 'anything', '1', undef, '1');
my $Tval   = simple_type('value', 'not a reference', 'not ref $value', undef, '');
my $Tstr   = simple_type('str', undef, undef, $Tval );
my $Tint   = simple_type('int', 'integer number', 'int $value eq $value', $Tval, 0);
my $Tpint  = simple_type('pos_int', 'positive integer', '$value >= 0', $Tint);
my $Tarray = simple_type('ARRAY', 'array reference', 'ref $value eq "ARRAY"', undef, $crefdef);
my $Ttype  = simple_type('ARRAY', 'array reference', 'ref $value eq "ARRAY"', $Tstr, 'ANY');
my $btclass = 'Kephra::Base::Data::Type::Basic';
my $ptclass = 'Kephra::Base::Data::Type::Parametric';

my $Tindex = para_type('index', 'valid index of array', {name => 'array', parent => $Tarray},    # inherit both defaults
                       'return "value $value is out of range" if $value >= @$param', $Tpint);
my $Tref = para_type({name => 'reference', help => 'reference of given type', parameter => {name => 'refname', parent => $Tstr, default => 'ARRAY'}, 
                     code => 'return "value $value is not a $param reference" if ref $value ne $param', parent => $Tany, default => $erefdef}); # overwrite both defaults
my $Tshortref = para_type({name => 'short_ref', help => 'reference with short, given name',  
                     code => 'return "reference $param is too long " if length $param > 9',             parent => $Tref}); # 

is ( ref $Tindex, $ptclass,                    'created first prametric type object, type "index" with positional arguments');
is ( $Tindex->get_name, 'index',               'got attribute "name" from getter of "index"');
is ( $Tindex->get_help, 'valid index of array','got attribute "help" from getter of "index"');
is ( $Tindex->get_default_value, 0,            'got attribute "default" value from getter of "index"');
my $param = $Tindex->get_parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "index"');
is ( $param->get_name, 'array',                'got attribute "name" from "index" parameter');
is ( $param->get_default_value, $crefdef,      'got attribute "default" from "index" parameter');
my $checker = $Tindex->get_checker;
my $tchecker = $Tindex->get_trusting_checker;
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
is ( $Tindex->check(0,[1,2,3]), '',            'check method of type "index" accepts correctly min index 0');
is ( $Tindex->check(2,[1,2,3]), '',            'check method of type "index" accepts correctly max index 2');
ok ( $Tindex->check(-1,[1,2,3]),               'check method of type "index" denies with error correctly negative index');
ok ( $Tindex->check(3,[1,2,3]),                'check method of type "index" denies with error correctly too large index');
ok ( $Tindex->check('-',[1,2,3]),              'check method of type "index" denies with error correctly none number index');
ok ( $Tindex->check([],[1,2,3]),               'check method of type "index" denies with error correctly none value index');
ok ( $Tindex->check(0,{1=>2}),                 'check method of type "index" denies with error correctly none ARRAY parameter');

my $state = $Tindex->state;
is ( ref $state, 'HASH',                       'state of "index" type is a HASH ref');
is ( ref $state->{'parameter'}, 'HASH',        'state of "index" type parameter is a HASH ref');
is ( $state->{'name'},          'index',       '"name" in type "index" state HASH is correct');
is ( $state->{'parameter'}{'name'}, 'array',   'parameter "name" in type "index" state is correct');
my $Ticlone = Kephra::Base::Data::Type::Parametric->restate($state);
is ( ref $Ticlone, $ptclass,                   'recreated first prametric type object, type "index" by restate from dumped state');
is ( $Ticlone->get_name, 'index',              'got attribute "name" from getter of "index" clone');
is ( $Ticlone->get_help,'valid index of array','got attribute "help" from getter of "index" clone');
is ( $Ticlone->get_default_value, 0,           'got attribute "default" value from getter of "index" clone');
$param = $Ticlone->get_parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "index" clone');
is ( $param->get_name, 'array',                'got attribute "name" from "index" clone parameter');
is ( $param->get_default_value, $crefdef,      'got attribute "default" from "index" clone parameter');
$checker = $Ticlone->get_checker;
$tchecker = $Ticlone->get_trusting_checker;
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
is ( $Ticlone->check(0,[1,2,3]), '',           'check method of type "index" clone accepts correctly min index 0');
is ( $Ticlone->check(2,[1,2,3]), '',           'check method of type "index" clone accepts correctly max index 2');
ok ( $Ticlone->check(-1,[1,2,3]),              'check method of type "index" clone denies with error correctly negative index');
ok ( $Tindex->check('-',[1,2,3]),              'check method of type "index" clone denies with error correctly none number index');
ok ( $Tindex->check([],[1,2,3]),               'check method of type "index" clone denies with error correctly none value index');
ok ( $Tindex->check(0,{1=>2}),                 'check method of type "index" clone denies with error correctly none ARRAY parameter');

$Tindex = para_type('index', 'valid index of array', $Tarray, 'return "value $value is out of range" if $value >= @$param', $Tpint);
is ( ref $Tindex, $ptclass,                    'created first prametric type "index" with direct type object as parameter');
is ( $Tindex->get_name, 'index',               'got attribute "name" from getter of "index"');
is ( $Tindex->get_help, 'valid index of array','got attribute "help" from getter of "index"');
is ( $Tindex->get_default_value, 0,            'got attribute "default" value from getter of "index"');
$param = $Tindex->get_parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "index"');
is ( $param->get_name, 'ARRAY',                'got attribute "name" from "index" parameter');
is ( $param->get_default_value, $crefdef,      'got attribute "default" from "index" parameter');
$checker = $Tindex->get_checker;
$tchecker = $Tindex->get_trusting_checker;
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
is ( $Tref->get_name, 'reference',             'got attribute "name" from getter of type "ref"');
is ( $Tref->get_help,'reference of given type','got attribute "help" from getter of type "ref"');
is ( $Tref->get_default_value, $erefdef,       'got attribute "default" value from getter of "ref"');
$param = $Tref->get_parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "ref"');
is ( $param->get_name, 'refname',              'got attribute "name" from "ref" parameter');
is ( $param->get_default_value, 'ARRAY',       'got attribute "default" from "ref" parameter');
$checker = $Tref->get_checker;
$tchecker = $Tref->get_trusting_checker;
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
is ( $Tref->check( {}, 'HASH'), '',            'check method of type "ref" accepts correctly HASH ref');
is ( $Tref->check( sub {}, 'CODE'), '',        'check method of type "ref" accepts correctly CODE ref');
is ( $Tref->check( $Tref, $ptclass), '',       'check method of type "ref" accepts correctly own ref');
is ( $Tref->check(1, ''), '',                  'check method of type "ref" accepts correctly none ref');
ok ( $Tref->check([],'Regex'),                 'check method of type "ref" denies with error correctly ARRAY ref as not a Regex ref');
ok ( $Tref->check([],[]),                      'check method of type "ref" denies with error correctly when parameter is not a str');

$state = $Tref->state;
is ( ref $state, 'HASH',                       'state of "ref" type is a HASH ref');
is ( ref $state->{'parameter'}, 'HASH',        'state of "ref" type parameter is a HASH ref');
is ( $state->{'name'},          'reference',   '"name" in type "ref" state HASH is correct');
is ( $state->{'parameter'}{'name'}, 'refname', 'parameter "name" in type "ref" state is correct');
my $Trefclone = Kephra::Base::Data::Type::Parametric->restate($state);
is ( ref $Trefclone, $ptclass,                 'recreated prametric type object, "ref" by restate from dumped state');
is ( $Trefclone->get_name, 'reference',        'got attribute "name" from getter of "ref" clone');
is ( $Trefclone->get_help, 'reference of given type','got attribute "help" from getter of "ref" clone');
is ( $Trefclone->get_default_value, $erefdef,  'got attribute "default" value from getter of "ref"');
$param = $Trefclone->get_parameter();
is ( ref $param, $btclass,                     'got attribute "parameter" object from getter of "ref" clone');
is ( $param->get_name, 'refname',              'got attribute "name" from "ref" clone parameter');
is ( $param->get_default_value, 'ARRAY',       'got attribute "default" from "ref" clone parameter');
$checker = $Trefclone->get_checker;
$tchecker = $Trefclone->get_trusting_checker;
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
is ( $Trefclone->check( {}, 'HASH'), '',       'check method of type "ref" clone accepts correctly HASH ref');
is ( $Trefclone->check( sub {}, 'CODE'), '',   'check method of type "ref" clone accepts correctly CODE ref');
is ( $Trefclone->check( $Tref, $ptclass), '',  'check method of type "ref" clone accepts correctly own ref');
is ( $Trefclone->check(1, ''), '',             'check method of type "ref" clone accepts correctly none ref');
ok ( $Trefclone->check([],'Regex'),            'check method of type "ref" clone denies with error correctly ARRAY ref as not a Regex ref');
ok ( $Trefclone->check([],[]),                 'check method of type "ref" clone denies with error correctly when parameter is not a str');

is ( ref $Tshortref, $ptclass,                      'created prametric type that inherits from another param type');
is ( $Tshortref->get_name, 'short_ref',             'got attribute "name" from getter of type "short_ref"');
is ( $Tshortref->get_help,'reference with short, given name', 'got attribute "help" from getter of type "short_ref"');
is ( $Tshortref->get_default_value, $erefdef,       'got attribute "default" value from getter of "short_ref" (was inherited properly)');
$param = $Tshortref->get_parameter();
is ( ref $param, $btclass,                          'got attribute "parameter" object from getter of "short_ref" (was inherited properly)');
is ( $param->get_name, 'refname',                   'got attribute "name" from "short_ref" parameter');
is ( $param->get_default_value, 'ARRAY',            'got attribute "default" from "short_ref" parameter (was inherited properly)');
$checker = $Tshortref->get_checker;
$tchecker = $Tshortref->get_trusting_checker;
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

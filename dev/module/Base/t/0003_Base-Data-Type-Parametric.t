#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Parametric;
use Test::More tests => 120;

sub simple_type { Kephra::Base::Data::Type::Simple->new(@_) }
sub para_type { Kephra::Base::Data::Type::Parametric->new(@_) }

my $erefdef = [];
my $crefdef = [1];
my $Tany   = simple_type('ANY', 'anything', '1', undef, '1');
my $Tval   = simple_type('value', 'not a reference', 'not ref $value', undef, '');
my $Tstr   = simple_type('str', undef, undef, $Tval );
my $Tint   = simple_type('int', 'integer number', 'int $value eq $value', $Tval, 0);
my $Tpint  = simple_type('pos_int', 'positive integer', '$value >= 0', $Tint);
my $Tarray = simple_type('ARRAY', 'array reference', 'ref $value eq "ARRAY"', undef, []);
my $Ttype  = simple_type('ARRAY', 'array reference', 'ref $value eq "ARRAY"', $Tstr, 'ANY');
my $sclass  = 'Kephra::Base::Data::Type::Simple';
my $class  = 'Kephra::Base::Data::Type::Parametric';

my $Tindex = para_type('index', 'valid index of array', {name => 'array', type => $Tarray, default => $crefdef}, 
                       'return "value $value is out of range" if $value >= @$param', $Tpint, 0);
my $Tref = para_type({name => 'reference', help => 'reference of given type', parameter => {name => 'refname', type => $Tstr, default => 'ARRAY'}, 
                     code => 'return "value $value is not a $param reference" if ref $value ne $param', parent => $Tany, default => $erefdef});

is ( ref $Tindex, $class,                      'created first prametric type object, type "index" with positional arguments');
is ( $Tindex->get_name, 'index',               'got attribute "name" from getter of "index"');
is ( $Tindex->get_help, 'valid index of array','got attribute "help" from getter of "index"');
is ( $Tindex->get_default_value, 0,            'got attribute "default" value from getter of "index"');
my $param = $Tindex->get_parameter();
is ( ref $param, $sclass,                      'got attribute "parameter" object from getter of "index"');
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
is ( ref $Ticlone, $class,                     'recreated first prametric type object, type "index" by restate from dumped state');
is ( $Ticlone->get_name, 'index',              'got attribute "name" from getter of "index" clone');
is ( $Ticlone->get_help,'valid index of array','got attribute "help" from getter of "index" clone');
is ( $Ticlone->get_default_value, 0,           'got attribute "default" value from getter of "index" clone');
my $param = $Ticlone->get_parameter();
is ( ref $param, $sclass,                      'got attribute "parameter" object from getter of "index" clone');
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


is ( ref $Tref, $class,                        'created second prametric type object, type "ref" with named arguments');
is ( $Tref->get_name, 'reference',             'got attribute "name" from getter of type "ref"');
is ( $Tref->get_help,'reference of given type','got attribute "help" from getter of type "ref"');
is ( $Tref->get_default_value, $erefdef,       'got attribute "default" value from getter of "ref"');
$param = $Tref->get_parameter();
is ( ref $param, $sclass,                      'got attribute "parameter" object from getter of "ref"');
is ( $param->get_name, 'refname',              'got attribute "name" from "ref" parameter');
is ( $param->get_default_value, 'ARRAY',       'got attribute "default" from "ref" parameter');
$checker = $Tref->get_checker;
$tchecker = $Tref->get_trusting_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->( {}, 'HASH'), '',              'checker of type "ref" accepts correctly HASH ref');
is ( $checker->( sub {}, 'CODE'), '',          'checker of type "ref" accepts correctly CODE ref');
is ( $checker->( $Tref, $class), '',           'checker of type "ref" accepts correctly own ref');
is ( $checker->(1, ''), '',                    'checker of type "ref" accepts correctly none ref');
ok ( $checker->([],'Regex'),                   'checker of type "ref" denies with error correctly ARRAY ref as not a Regex ref');
ok ( $checker->([],[]),                        'checker of type "ref" denies with error correctly when parameter is not a str');
is ( ref $tchecker, 'CODE',                    'attribute "trusting checker" is a CODE ref');
is ( $tchecker->( {}, 'HASH'), '',             'trusting checker of type "ref" accepts correctly HASH ref');
is ( $tchecker->( sub {}, 'CODE'), '',         'trusting checker of type "ref" accepts correctly CODE ref');
is ( $tchecker->( $Tref, $class), '',          'trusting checker of type "ref" accepts correctly own ref');
is ( $tchecker->(1, ''), '',                   'trusting checker of type "ref" accepts correctly none ref');
ok ( $tchecker->([],'Regex'),                  'trusting checker of type "ref" denies with error correctly ARRAY ref as not a Regex ref');
is ( $Tref->check( {}, 'HASH'), '',            'check method of type "ref" accepts correctly HASH ref');
is ( $Tref->check( sub {}, 'CODE'), '',        'check method of type "ref" accepts correctly CODE ref');
is ( $Tref->check( $Tref, $class), '',         'check method of type "ref" accepts correctly own ref');
is ( $Tref->check(1, ''), '',                  'check method of type "ref" accepts correctly none ref');
ok ( $Tref->check([],'Regex'),                 'check method of type "ref" denies with error correctly ARRAY ref as not a Regex ref');
ok ( $Tref->check([],[]),                      'check method of type "ref" denies with error correctly when parameter is not a str');

my $state = $Tref->state;
is ( ref $state, 'HASH',                       'state of "ref" type is a HASH ref');
is ( ref $state->{'parameter'}, 'HASH',        'state of "ref" type parameter is a HASH ref');
is ( $state->{'name'},          'reference',   '"name" in type "ref" state HASH is correct');
is ( $state->{'parameter'}{'name'}, 'refname', 'parameter "name" in type "ref" state is correct');
my $Trefclone = Kephra::Base::Data::Type::Parametric->restate($state);
is ( ref $Trefclone, $class,                   'recreated prametric type object, "ref" by restate from dumped state');
is ( $Trefclone->get_name, 'reference',        'got attribute "name" from getter of "ref" clone');
is ( $Trefclone->get_help, 'reference of given type','got attribute "help" from getter of "ref" clone');
is ( $Trefclone->get_default_value, $erefdef,  'got attribute "default" value from getter of "ref"');
$param = $Trefclone->get_parameter();
is ( ref $param, $sclass,                      'got attribute "parameter" object from getter of "ref" clone');
is ( $param->get_name, 'refname',              'got attribute "name" from "ref" clone parameter');
is ( $param->get_default_value, 'ARRAY',       'got attribute "default" from "ref" clone parameter');
$checker = $Trefclone->get_checker;
$tchecker = $Trefclone->get_trusting_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->( {}, 'HASH'), '',              'checker of type "ref" clone accepts correctly HASH ref');
is ( $checker->( sub {}, 'CODE'), '',          'checker of type "ref" clone accepts correctly CODE ref');
is ( $checker->( $Tref, $class), '',           'checker of type "ref" clone accepts correctly own ref');
is ( $checker->(1, ''), '',                    'checker of type "ref" clone accepts correctly none ref');
ok ( $checker->([],'Regex'),                   'checker of type "ref" clone denies with error correctly ARRAY ref as not a Regex ref');
ok ( $checker->([],[]),                        'checker of type "ref" clone denies with error correctly when parameter is not a str');
is ( ref $tchecker, 'CODE',                    'attribute "trusting checker" is a CODE ref');
is ( $tchecker->( {}, 'HASH'), '',             'trusting checker of type "ref" clone accepts correctly HASH ref');
is ( $tchecker->( sub {}, 'CODE'), '',         'trusting checker of type "ref" clone accepts correctly CODE ref');
is ( $tchecker->( $Tref, $class), '',          'trusting checker of type "ref" clone accepts correctly own ref');
is ( $tchecker->(1, ''), '',                   'trusting checker of type "ref" clone accepts correctly none ref');
ok ( $tchecker->([],'Regex'),                  'trusting checker of type "ref" clone denies with error correctly ARRAY ref as not a Regex ref');
is ( $Trefclone->check( {}, 'HASH'), '',       'check method of type "ref" clone accepts correctly HASH ref');
is ( $Trefclone->check( sub {}, 'CODE'), '',   'check method of type "ref" clone accepts correctly CODE ref');
is ( $Trefclone->check( $Tref, $class), '',    'check method of type "ref" clone accepts correctly own ref');
is ( $Trefclone->check(1, ''), '',             'check method of type "ref" clone accepts correctly none ref');
ok ( $Trefclone->check([],'Regex'),            'check method of type "ref" clone denies with error correctly ARRAY ref as not a Regex ref');
ok ( $Trefclone->check([],[]),                 'check method of type "ref" clone denies with error correctly when parameter is not a str');

exit 0;

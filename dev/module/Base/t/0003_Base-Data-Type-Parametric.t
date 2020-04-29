#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Parametric;
use Test::More tests => 60;

sub simple_type { Kephra::Base::Data::Type::Simple->new(@_) }
sub para_type { Kephra::Base::Data::Type::Parametric->new(@_) }

my $refdef = [];
my $Tany = simple_type('ANY', 'anything', '1', undef, '1');
my $Tval = simple_type('value', 'not a reference', 'not ref $value', undef, '');
my $Tstr = simple_type('str', undef, undef, $Tval );
my $Tint = simple_type('int', 'integer number', 'int $value eq $value', $Tval, 0);
my $Tpint = simple_type('pos_int', 'positive integer', '$value >= 0', $Tint);
my $Tarray = simple_type('ARRAY', 'array reference', 'ref $value eq "ARRAY"', undef, []);
my $Ttype = simple_type('ARRAY', 'array reference', 'ref $value eq "ARRAY"', $Tstr, 'ANY');
my $class = 'Kephra::Base::Data::Type::Parametric';

my $Tindex = para_type('index', 'valid index of array', {name => 'array', type => $Tarray, default => [1]}, 
                       'return "value $value is out of range" if $value >= @$param', $Tpint, 0);
my $Tref = para_type({name => 'reference', help => 'reference of given type', parameter => {name => 'refname', type => $Tval, default => 'ARRAY'}, 
                     code => 'return "value $value is not a $param reference" if ref $value ne $param', parent => $Tany, default => $refdef});

is ( ref $Tindex, $class,                      'created first prametric type object, type "index" with positional arguments');
is ( $Tindex->get_name, 'index',               'got attribute "name" from getter of "index"');
is ( $Tindex->get_help, 'valid index of array','got attribute "help" from getter of "index"');
is ( $Tindex->get_default_value, 0,            'got attribute "default" value from getter of index');
my $checker = $Tindex->get_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->(0,[1,2,3]), '',                'checker of type "index" has true positive result');
is ( $checker->(2,[1,2,3]), '',                'checker of type "index" has second true positive result');
ok ( $checker->(-1,[1,2,3]),                   'checker of type "index" has true false result');        # error on purpose
ok ( $checker->(3,[1,2,3]),                    'checker of type "index" has second true false result');
is ( $Tindex->check(0,[1,2,3]), '',            'type "index" had true positive result');
is ( $Tindex->check(2,[1,2,3]), '',            'type "index" has second true positive result');
ok ( $Tindex->check(-1,[1,2,3]),               'type "index" has true false result');        # error on purpose
ok ( $Tindex->check(3,[1,2,3]),                'type "index" has second true false result');

my $state = $Tindex->state;
is ( ref $state, 'HASH',                       'state of "index" type is a HASH ref');
is ( ref $state->{'parameter'}, 'HASH',        'state of "index" type parameter is a HASH ref');
is ( $state->{'name'},          'index',       '"name" in type "index" state HASH is correct');
is ( $state->{'parameter'}{'name'}, 'array',   'parameter "name" in type "index" state is correct');
my $Ticlone = Kephra::Base::Data::Type::Parametric->restate($state);
is ( ref $Ticlone, $class,                     'recreated first prametric type object, type "index" by restate from dumped state');
is ( $Ticlone->get_name, 'index',              'got attribute "name" from getter of index');
is ( $Ticlone->get_help,'valid index of array','got attribute "help" from getter of index');
is ( $Ticlone->get_default_value, 0,           'got attribute "default" value from getter of index');
$checker = $Ticlone->get_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->(0,[1,2,3]), '',                'checker of type "index" has true positive result');
is ( $checker->(2,[1,2,3]), '',                'checker of type "index" has second true positive result');
ok ( $checker->(-1,[1,2,3]),                   'checker of type "index" has true false result');        # error on purpose
ok ( $checker->(3,[1,2,3]),                    'checker of type "index" has second true false result');
is ( $Ticlone->check(0,[1,2,3]), '',           'type "index" had true positive result');
is ( $Ticlone->check(2,[1,2,3]), '',           'type "index" has second true positive result');
ok ( $Ticlone->check(-1,[1,2,3]),              'type "index" has true false result');        # error on purpose
ok ( $Ticlone->check(3,[1,2,3]),               'type "index" has second true false result');


is ( ref $Tref, $class,                        'created second prametric type object, type "ref" with named arguments');
is ( $Tref->get_name, 'reference',             'got attribute "name" from getter of "ref"');
is ( $Tref->get_help, 'reference of given type','got attribute "help" from getter of "ref"');
is ( $Tref->get_default_value, $refdef,        'got attribute "default" value from getter of "ref"');
$checker = $Tref->get_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->( {}, 'HASH'), '',              'checker of type "ref" has true positive result');
is ( $checker->( sub {}, 'CODE'), '',          'checker of type "ref" has second true positive result');
is ( $checker->(1, ''), '',                    'checker of type "ref" has third true positive result');
ok ( $checker->([],'Regex'),                   'checker of type "ref" has true false result');        # error on purpose
is ( $Tref->check( {}, 'HASH'), '',            'type "ref" had true positive result');
is ( $Tref->check( sub {}, 'CODE'), '',        'type "ref" has second true positive result');
is ( $Tref->check(1, ''), '',                  'type "ref" has third true result');
ok ( $Tref->check([],'Regex'),                 'type "ref" has true false result'); # error on purpose

my $state = $Tref->state;
is ( ref $state, 'HASH',                       'state of "ref" type is a HASH ref');
is ( ref $state->{'parameter'}, 'HASH',        'state of "ref" type parameter is a HASH ref');
is ( $state->{'name'},          'reference',   '"name" in type "ref" state HASH is correct');
is ( $state->{'parameter'}{'name'}, 'refname', 'parameter "name" in type "ref" state is correct');
my $Trefclone = Kephra::Base::Data::Type::Parametric->restate($state);
is ( ref $Trefclone, $class,                   'recreated prametric type object, "ref" by restate from dumped state');
is ( $Trefclone->get_name, 'reference',        'got attribute "name" from getter of "ref"');
is ( $Trefclone->get_help, 'reference of given type','got attribute "help" from getter of "ref"');
is ( $Trefclone->get_default_value, $refdef,   'got attribute "default" value from getter of "ref"');
$checker = $Trefclone->get_checker;
is ( ref $checker, 'CODE',                     'attribute "checker" is a CODE ref');
is ( $checker->( {}, 'HASH'), '',              'checker of type "ref" has true positive result');
is ( $checker->( sub {}, 'CODE'), '',          'checker of type "ref" has second true positive result');
is ( $checker->(1, ''), '',                    'checker of type "ref" has third true positive result');
ok ( $checker->([],'Regex'),                   'checker of type "ref" has true false result');        # error on purpose
is ( $Trefclone->check( {}, 'HASH'), '',       'type "ref" had true positive result');
is ( $Trefclone->check( sub {}, 'CODE'), '',   'type "ref" has second true positive result');
is ( $Trefclone->check(1, ''), '',             'type "ref" has third true result');
ok ( $Trefclone->check([],'Regex'),            'type "ref" has true false result'); # error on purpose

exit 0;

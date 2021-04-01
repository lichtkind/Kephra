#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Util;  
use Kephra::Base::Package;

package TypeTester; 
use Test::More tests => 50 + @Kephra::Base::Data::Type::Util::type_class_names;

sub is_type { &Kephra::Base::Data::Type::Util::is_type  }
sub can_s   { &Kephra::Base::Data::Type::Util::can_substitude_names }
sub subst   { &Kephra::Base::Data::Type::Util::substitude_names }
sub create  { &Kephra::Base::Data::Type::Util::create_type }

for my $package (@Kephra::Base::Data::Type::Util::type_class_names){
    is (Kephra::Base::Package::package_loaded($package),      1,   "Type class $package is loaded and seems to belong to Types" );
}

is( can_s({name => 'a', parent => {}}),                           0,   'basic type definition with no type name to substitute');
is( can_s({name => 'a', parent => ''}),                           1,   'basic type definition with a basic type name to substitute');
is( can_s({name => 'a', parent => []}),                           1,   'type definition with a parametric name to substitute');
is( can_s({name => 'a', parent => {}, parameter => {}}),          0,   'parametric type definition with no type name to substitute');
is( can_s({name => 'a', parent => '', parameter => {}}),          1,   'parametric type definition with one type name of parent to substitute');
is( can_s({name => 'a', parent => {}, parameter => ''}),          1,   'parametric type definition with one type name of parameter to substitute');
is( can_s({name => 'a', parent => '', parameter => ''}),          2,   'parametric type definition with two type names to substitute');
is( can_s({name => 'a', parent => '', parameter => {parent => ''}}), 2, 'two: parameter parent and parent');
is( can_s({name => 'a', parent => [], parameter => {parent => ''}}), 2, 'two: parametric parent and parent of parameter');


my $store = Kephra::Base::Data::Type::Store->new();
$store->add_type({name => 'value', help => 'defined value',  code =>'defined $value', default => ''});
$store->add_type({name => 'str',   help => 'string',         code =>'not ref $value',               parent => $store->get_type('value')});
$store->add_type({name => 'ref',   help => 'reference',      code =>'ref $value',     default => []});
$store->add_type({name => 'ref',   help => 'named reference',code =>'ref $value eq $param',         parent => $store->get_type('ref'),
                                   parameter => {name => 'name', default => 'ARRAY', parent => $store->get_type('str')}});


is( is_type( $store->get_type('str') ),                           1,   'basic type is a type object');
is( is_type( $store->get_type('ref', 'name') ),                   1,   'parametric type is a type object');
is( is_type( undef ),                                             0,   'undef is not a type object');
is( is_type( 1 ),                                                 0,   'a number is not a type object');
is( is_type( [] ),                                                0,   'ARRAY ref is a type object');
is( is_type( bless([]) ),                                         0,   'an arbitrary object is not a type object');


is( subst({name => 'a',                }, $store),                0,   'no type parent in definition, nothing to be replaced');
my $type_def = {name => 'a', parent => 'int' };
is( subst($type_def, $store),                                     0,   'no type name in definition that can be replaced');
is( ref $type_def->{'parent'},                                   '',   'no type parent name was replaced');
is( $type_def->{'name'},                                        'a',   'other keys were not changed');
is( keys %$type_def,                                              2,   'no new keys created by substitution');
$type_def = {name => 'a', parent => 'ref'};
is( subst($type_def, $store),                                     1,   'basic type name in definition that can be found in store');
is( ref $type_def->{'parent'},    'Kephra::Base::Data::Type::Basic',   'type parent name was replaced with basictype object');
is( $type_def->{'name'},                                        'a',   'other keys were not changed');
is( keys %$type_def,                                              2,   'no new keys created by substitution');
$type_def = {name => 'a', parent => ['ref','name']};
is( subst($type_def, $store),                                     1,   'parametric type name in definition that can be found in store');
is( ref $type_def->{'parent'},'Kephra::Base::Data::Type::Parametric',  'type parnet name was replaced with parametric type object');
is( $type_def->{'name'},                                        'a',   'other keys were not changed');
is( keys %$type_def,                                              2,   'no new keys created by substitution');
is( subst({name => 'a', parameter => '-'}, $store),               0,   'no parameter type definition that can be found in store');
$type_def = {name => 'a', parameter => 'ref'};
is( subst($type_def, $store),                                     1,   'basic type name from store in type parameter definition that be replaced');
is( ref $type_def->{'parameter'}, 'Kephra::Base::Data::Type::Basic',   'type parmeter name was replaced with basictype object');
is( $type_def->{'name'},                                        'a',   'other keys were not changed');
is( keys %$type_def,                                              2,   'no new keys created by substitution');
$type_def = {name => 'a', parameter => {parent => 'ref'}};
is( subst($type_def, $store),                                     1,   'basic type name from store in type parameter definition (parent) that be replaced');
is( ref $type_def->{'parameter'}{'parent'}, 'Kephra::Base::Data::Type::Basic',   'type parameter parent name was replaced with basictype object');
is( keys %$type_def,                                              2,   'no new keys created by substitution');
is( keys %{$type_def->{'parameter'}},                             1,   'no new parameter keys created by substitution');
$type_def = {name => 'a', parameter=>{parent=>['ref','name']}};
is( subst($type_def, $store),                                     0,   'parameter parent can never be a parametric type itself');
is( $type_def->{'parameter'}{'parent'}[0],                    'ref',   'parameter type name was not changed');
is( $type_def->{'parameter'}{'parent'}[1],                   'name',   'parameter type parameter name was not changed');
is( subst({name => 'a', parameter => ['ref','name']}, $store),    0,   'parameter can never be a parametric type itself');
$type_def = {name => 'b', parent=>'str',parameter=>'ref'};
is( subst($type_def, $store),                                     2,   'parent and parameter can be replaced at same time');
is( ref $type_def->{'parent'},    'Kephra::Base::Data::Type::Basic',   'type parent name was replaced with basictype object');
is( ref $type_def->{'parameter'}, 'Kephra::Base::Data::Type::Basic',   'type parmeter name was replaced with basictype object');
is( $type_def->{'name'},                                        'b',   'other keys were not changed');
is( keys %$type_def,                                              3,   'no new keys created by substitution');


my $type = create({name => 'array', help => 'reference', code => 'ref $value eq "ARRAY"', default=>[0]}, $store);
is( is_type($type),                                               1,   'could create basic type without parent');
$store->add_type($type);
$type = create({name => 'int', help => 'integer', code => 'int $value eq $value', parent => 'str', default=>0}, $store);
is( is_type($type),                                               1,   'could create basic type with parent from store');
$store->add_type($type);
$type = create({name => 'index', help => 'index of array', code => '$value < @$param', parent => 'int', parameter => {name => 'array', parent => 'array', default => [0]}}, $store);
is( is_type($type),                                               1,   'could create parametric type with parent and parameter parent from store');
$type = create({name => 'index', help => 'index of array', code => '$value < @$param', parent => 'int', parameter => 'array'} , $store);
is( is_type($type),                                               1,   'could create parametric type with parent and parameter from store');

exit 0;
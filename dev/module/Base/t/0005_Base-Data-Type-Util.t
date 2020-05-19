#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store; 
use Kephra::Base::Data::Type::Util;  

package TypeTester; 
use Test::More tests => 29;

sub is_type  { &Kephra::Base::Data::Type::Util::is_type  }
sub can_s   { &Kephra::Base::Data::Type::Util::can_substitude_names }
sub subst   { &Kephra::Base::Data::Type::Util::substitude_names }
sub create  { &Kephra::Base::Data::Type::Util::create_type }

is( can_s({name => 'a', parent => {}}),                       0,   'basic type definition with no type name to substitute');
is( can_s({name => 'a', parent => ''}),                       1,   'basic type definition with a basic type name to substitute');
is( can_s({name => 'a', parent => []}),                       1,   'type definition with a parametric name to substitute');
is( can_s({name => 'a', parent => {}, parameter => {}}),      0,   'parametric type definition with no type name to substitute');
is( can_s({name => 'a', parent => '', parameter => {}}), 1 , 'parametric type definition with one type name of parent to substitute');
is( can_s({name => 'a', parent => {}, parameter => ''}), 1 , 'parametric type definition with one type name of parameter to substitute');
is( can_s({name => 'a', parent => '', parameter => ''}), 2 , 'parametric type definition with two type names to substitute');
is( can_s({name => 'a', parent => '', parameter => {parent => ''}}), 2 , 'two: parameter parent and parent');
is( can_s({name => 'a', parent => [], parameter => {parent => ''}}), 2 , 'two: parametric parent and parent of parameter');

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
is( subst({name => 'a', parent => 'int'}, $store),                0,   'no type name in definition that can be replaced');
is( subst({name => 'a', parent => 'ref'}, $store),                1,   'basic type name in definition that can be found in store');
is( subst({name => 'a', parent => ['ref','name']}, $store),       1,   'parametric type name in definition that can be found in store');
is( subst({name => 'a', parameter => '-'}, $store),               0,   'no parameter type definition that can be found in store');
is( subst({name => 'a', parameter => 'ref'}, $store),             1,   'basic type name from store in type parameter definition that be replaced');
is( subst({name => 'a', parameter => {parent => 'ref'}}, $store), 1,   'basic type name from store in type parameter definition (parent) that be replaced');
is( subst({name => 'a', parameter=>{parent=>['ref','name']}},$store),0,'parameter parent can never be a parametric type itself');
is( subst({name => 'a', parameter => ['ref','name']}, $store),    0,   'parameter can never be a parametric type itself');
is( subst({name => 'a', parent=>'str',parameter=>'ref'}, $store), 2,   'parent and parameter can be replaced at same time');

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
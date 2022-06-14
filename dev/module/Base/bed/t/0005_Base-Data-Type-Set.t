#!/usr/bin/perl -w
use v5.20;
use warnings;
#use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

package NameSpaceTester; 
use Test::More tests => 211;

use Kephra::Base::Data::Type::Basic;       my $bclass  = 'Kephra::Base::Data::Type::Basic';
use Kephra::Base::Data::Type::Parametric;  my $pclass  = 'Kephra::Base::Data::Type::Parametric';
                                           my $sclass  = 'Kephra::Base::Data::Type::Set';

my $val_def  = { name=> 'value',  help=> 'defined value',     code=> 'defined $value',                             default=> '',     };
my $nref_def = { name=> 'no_ref', help=> 'not a reference',   code=> 'not ref $value',        parent=> 'value',              ,  symbol => '$'};
my $int_def  = { name=> 'int',    help=> 'integer',           code=> 'int($value) eq $value', parent=> 'no_ref',   default=> 0, symbol => 'N'};
my $ip_def   = { name=> 'int_pos',help=> 'greater equal zero',code=>'$value >= 0',            parent=> 'int'};
my $aref_def = { name=> 'array_ref',help=> 'array reference', code=> q/ref $value eq 'ARRAY'/,                     default=> []};
my $nea_def  = { name=> 'nemty_array',help=>'array with content',code=> '@$value',            parent => 'array_ref', default=> [1]};

my $dindex_def ={name => 'index', help=> 'valid index of array',code=> 'return "value $value is out of range" if $value >= @$param', symbol => 'I', 
                     parent=> 'int_pos',  parameter => 'nemty_array'} ;
my $para   = {name => 'simple_para', help => 'help', code => 1, default => 1, parameter => { name => 'param',  help => 'help', code => 1, default => 1, }};
my $bchild = {name => 'sb_child', help => 'help', code => 2, default => 2, parent => 'value', 
                                                                                  parameter => { name => 'bparam',  help => 'help', code => 1, default => 1, }};
my $pchild = {name => 'sp_child', help => 'help', code => 3, default => 3, parent => ['simple_para', 'param']};
my $nchild = {name => 'sn_child', help => 'help', code => 4, default => 4, parent => ['simple_para', 'para']};
my $param_name  = {name => 'sp_para', help => 'help', code => 5, default => 5, parameter => 'value'};
my $param_parent ={name => 'spp_para', help => 'help', code => 6, default => 6, parameter => { name => 'pp_param', help => 'help', code => 6.5, parent => 'value'}};
my $parent_param ={name => 'sppp_para', help => 'help', code => 7, default => 7, parent => 'value', parameter => { name => 'ppp_param', help => 'help', code => 5, parent => 'value'}};
my $index_def= { name=> 'index',  help=> 'valid index of array',code=> 'return "value $value is out of range" if $value >= @$param', symbol => 'I', 
                     parent=> 'int_pos',  parameter => {   name => 'array',  parent=> 'array_ref', default=> [1] }, };


eval "use $sclass;";
is( $@, '',                                                               'loaded namespace package');


my $space = Kephra::Base::Data::Type::Set->new();
is( ref $space, $sclass,                                                  'could create a closable type namespace object');
is( $space->list_type_names('basic'),                      undef,         'no basic types can be listed');
is( $space->list_type_names('param'),                      undef,         'no parametric types can be listed');
is( int($space->list_types( )),                                0,         'no type ID can be listed');
is( $space->list_type_symbols('basic'),                    undef,         'no basic symbols can be listed');
is( $space->list_type_symbols('param'),                    undef,         'no parametric symbols can be listed');
is( $space->list_forbidden_symbols(),                      undef,         'no forbidden symbols can be listed');
is( $space->type_name_from_symbol('&'),                    undef,         'requested symbol s not there');
is( $space->type_symbol_from_name('type'),                 undef,         'requested name of unknown symbol');
is( $space->get_type('type'),                              undef,         'requested type s not there');
is( $space->has_type('type'),                                  0,         'requested type s not there (bool answer)');
is( $space->is_open(),                                         1,         'newly made type namespace is open');
is( $space->close(),                                           1,         'could close namespace');
is( $space->is_open(),                                         0,         'namespace is closed now');
is( $space->close(),                                           0,         'can not close namespace twice');
like($space->add_type({}),                           qr/can not/,         'can not add types to closed namespace');
like($space->remove_type({}),                        qr/can not/,         'can not remove types from closed namespace');
like($space->forbid_symbols(1),                      qr/can not/,         'can not add to forbidden symbols of closed namespace');
like($space->allow_symbols(2),                       qr/can not/,         'can not remove from forbidden symbols at closed namespace');


my $ospace = Kephra::Base::Data::Type::Set->new('open');
is( ref $ospace, $sclass,                                                 'could create an unclosable type namespace object');
is( $ospace->is_open(),                                        1,         'newly made type namespace is open');
is( $ospace->close(),                                          0,         'could not close namespace');
is( $ospace->is_open(),                                        1,         'open type namespace is still open');


my $btype = $space->create_type($val_def);
is( ref $btype,                                          $bclass,         'could create simple basic type without deps');
my $ptype = $space->create_type($para);
is( ref $ptype,                                          $pclass,         'could create simple parametric type without deps');
is($space->need_resolve($val_def),                             0,         'nothing to resolve in simple basic type definition');
is($space->need_resolve($para),                                0,         'nothing to resolve in simple parametric type definition');
is($space->can_resolve($val_def),                              0,         'not need to resolve in simple basic type definition');
is($space->can_resolve($para),                                 0,         'not need to resolve in simple parametric type definition');

my @res = $ospace->add_type($btype);
is( int @res,                                                  2,         'could add basic type object');
is( $res[0],                                              $btype,         'got back added type object');
is( $res[1],                                        $btype->name,         'got back type name');
@res = $ospace->add_type($ptype);
is( int @res,                                                  2,         'could add parametric type object');
is( $res[0],                                              $ptype,         'got back added type object');
is( ref $res[1],                                         'ARRAY',         'got back type name in an ARRAY');
is( $res[1][0],                                     $ptype->name,         'got back type name');
is( $res[1][1],                          $ptype->parameter->name,         'got back type parameter name');
is( $ospace->has_type( $btype->name ),                         1,         'basic type storage confirmed');
is( $ospace->get_type( $btype->name ),                    $btype,         'can retrieve basic type from namespace');
is( $ospace->is_type_owned( $btype->name ),                    1,         'ownership of current package confirmed');
is( $ospace->has_type( $ptype->name,$ptype->parameter->name ), 1,         'param type storage confirmed');
is( $ospace->has_type( [$ptype->name,$ptype->parameter->name]),1,         'param type storage confirmed (ARRAY ref syntax)');
is( $ospace->get_type( $ptype->name,$ptype->parameter->name ), $ptype,    'can retrieve param type from namespace');
is( $ospace->get_type( [$ptype->name,$ptype->parameter->name]), $ptype,   'can retrieve param type from namespace (ARRAY ref syntax)');
is( $ospace->is_type_owned( $ptype->name,$ptype->parameter->name ), 1,    'ownership of current package confirmed');
is( $ospace->is_type_owned( [$ptype->name,$ptype->parameter->name] ), 1,  'ownership of current package confirmed (ARRAY ref syntax)');

package Foreign;
Test::More::is( $ospace->is_type_owned( $btype->name ),                    0,         'basic type owned by different package');
Test::More::like( $ospace->remove_type( $btype->name ),   qr/not be deleted/,         'foreign package can not remove basic type');
Test::More::is( $ospace->is_type_owned( $ptype->name,$ptype->parameter->name ), 0,    'param type owned by different package');
Test::More::is( $ospace->is_type_owned( [$ptype->name,$ptype->parameter->name] ), 0,  'param type owned by different package (ARRAY ref syntax)');
Test::More::like( $ospace->remove_type( $ptype->name,$ptype->parameter->name ),       qr/not be deleted/,         'foreign package can not remove param type');
Test::More::like( $ospace->remove_type( [$ptype->name,$ptype->parameter->name]),      qr/not be deleted/,         'foreign package can not remove param type (ARRAY ref syntax)');

package NameSpaceTester;
my @names = $ospace->list_type_names('basic');
is( int @names,                                                1,         'only one basic type was stored');
is( $names[0],                                      $btype->name,         'listed its name right');
@names = $ospace->list_type_names('param');
is( int @names,                                                1,         'only one parametric type was stored');
is( $names[0],                                      $ptype->name,         'listed its name right');
@names = $ospace->list_type_names('param', 'simple_para');
is( int @names,                                                1,         'only one sub type of parametric type was stored');
is( $names[0],                           $ptype->parameter->name,         'listed its name right');
my @symbols = $ospace->list_type_symbols('basic');
is( int @symbols,                                              0,         'no basic type symbols was stored yet');
@symbols = $ospace->list_type_symbols('param');
is( int @symbols,            
                                  0,         'no parametric type symbols was stored yet');
@names = $ospace->need_resolve($nref_def);
is( int @names,                                                1,         'parent of basic type needs to be resolved(name => obj ref)');
is( $names[0],                                      $btype->name,         'listed its name right');
@names = $ospace->can_resolve($nref_def);
is( int @names,                                                1,         'found parent name can be resolved');
is( $names[0],                                      $btype->name,         'listed its name right');
my $nrf_copy = {%$nref_def};
my ($known, $open) = $ospace->resolve_names($nrf_copy);
is( $known,                                                    1,         'found parent name to resolve');
is( $open,                                                     0,         'nothing else to resolve');
@names = $ospace->need_resolve($nrf_copy);
is( int @names,                                                0,         'parent of basic type was already resolved');
is( ref $ospace->create_type($nrf_copy),                 $bclass,         'parent was indeed resolved, could create type');
is( ref $ospace->create_type($nref_def),                 $bclass,         'created type object while resolving parent');
@names = $ospace->add_type( $nref_def );
is( $ospace->has_type( $nref_def->{'name'} ),                  1,         'created and added basic type that needed resolve');
@names = $ospace->list_type_names('basic');
is( int @names,                                                2,         'not there are two basic types in namespace');
@symbols = $ospace->list_type_symbols('basic');
is( int @symbols,                                              1,         'and one symbol for basic type');
is( $symbols[0],                                             '$',         'got correct symbol name');
is( $ospace->type_symbol_from_name($nref_def->{'name'}),     '$',         'got symbol related to baseic type name');
is( $ospace->type_name_from_symbol('$'),     $nref_def->{'name'},         'got name related to symbol');
my @ID = $ospace->list_types( );
is( @ID,                                                       3,         'now 3 type ID base, parametric and its parameter');


# adding nested type def of basic types and without owner
$ip_def->{'parent'} = $int_def;
@res = $ospace->add_type( $ip_def, undef, 1 );
is( int @res,                                                  3,         'could add 2 basic type object at once');
is( ref $res[0],                                         $bclass,         'got back type object  created from added def (child)');
is( $res[1],                                       $res[0]->name,         'names are consistent');
is( $res[1],                                   $ip_def->{'name'},         'got back type name');
is( $res[2],                                  $int_def->{'name'},         'got back parents type name');
@symbols = $ospace->list_type_symbols('basic');
is( int @symbols,                                              2,         'have now 3 symbls');
is( $ospace->type_symbol_from_name('int'),                   'N',         'got symbol related to baseic type name');
is( $ospace->type_name_from_symbol('N'),                   'int',         'got name related to symbol');
is( $ospace->is_type_owned( 'int' ),                           1,         'yes because type has no ownder');
package Foreign;
Test::More::is( $ospace->is_type_owned( 'int' ),               1,         'public basic type owned by different (all) packages');
package NameSpaceTester;
is($ospace->forbid_symbols('z'),                               0,         'can not forbid lc chars as Symbol');
is($ospace->forbid_symbols('ZZ'),                              0,         'can not forbid too loch str as Symbol');
is($ospace->forbid_symbols('Z'),                               1,         'forbid one Symbol');
like( $ospace->add_type( $aref_def, 'Z', 1 ),    qr/not allowed/,         'forbidded symbol was blocked as  it should');
@symbols = $ospace->list_forbidden_symbols;
is(int @symbols,                                               1,         'one Symbol is forbidden');
is( $symbols[0],                                             'Z',         'the Symbol is forbidden');
is($ospace->allow_symbols('a'),                                0,         'a was never forbidden');
is($ospace->allow_symbols('Z'),                                1,         'Z allowed again');
@res = $ospace->add_type( $aref_def, 'Z', 1 );
is( ref $res[0],                                         $bclass,         'now i can add basic type again');
@ID = $ospace->list_types( );
is( @ID,                                                       6,         'now 6 types in open set');

# replacing names in param type defs
@names = $ospace->need_resolve($bchild);
is( int @names,                                                1,         'parametric type with basic parent name, which needs to be resolved');
is( $names[0],                                      $btype->name,         'listed its name right');
@names = $ospace->can_resolve($bchild);
is( int @names,                                                1,         'found parent name can be resolved');
is( $names[0],                                      $btype->name,         'listed its name right');
my $tdef_copy = {%$bchild};
$tdef_copy->{'parameter'} = {%{$bchild->{'parameter'}}};
($known, $open) = $ospace->resolve_names($tdef_copy);
is( $known,                                                    1,         'found parent name and resolved it');
is( $open,                                                     0,         'nothing else to resolve');
is( $ospace->need_resolve($tdef_copy),                         0,         'says "need_resolve" too');
is( ref $ospace->create_type($tdef_copy),                $pclass,         'type object created from resolved type definition');
$tdef_copy = {%$bchild};
$tdef_copy->{'parameter'} = {%{$bchild->{'parameter'}}};
is( ref $ospace->create_type($tdef_copy),                $pclass,         'type object created and resolved type definition');
@names = $ospace->add_type( $bchild );
is( int @names,                                                3,         'resolved def, created object, and registered type and parameter');
is( ref $names[0],                                       $pclass,         'right kind of type object was created');
is( ref $names[1],                                       'ARRAY',         'created type object has parametric ID');
is( $names[1][0],                              $bchild->{'name'},         'type object was created under right name');
is( $names[1][1],                 $bchild->{'parameter'}{'name'},         'type object was created with right parameter name');
is( $names[2],                    $bchild->{'parameter'}{'name'},         'parameter typ object was created under right name');
is( $ospace->has_type( $bchild->{'name'}, $bchild->{'parameter'}{'name'} ),  1,         'type indeed was registered');
is( $ospace->has_type( $bchild->{'parameter'}{'name'} ),       1,         'parameter type indeed was registered');
@ID = $ospace->list_types( );
is( @ID,                                                       8,         'now 8 types in set');

@names = $ospace->need_resolve($pchild);
is( int @names,                                                1,         'parametric type with parametric parent name, which needs to be resolved');
is( ref $names[0],                                       'ARRAY',         'it is an param ID');
is( $names[0][0],                                  'simple_para',         'parametric type name is right');
is( $names[0][1],                                        'param',         'parameter type name is right');
@names = $ospace->can_resolve($pchild);
is( int @names,                                                1,         'found parent ID can be resolved');
is( ref $names[0],                                       'ARRAY',         'it is an param ID');
is( $names[0][0],                                  'simple_para',         'parametric type name is right');
is( $names[0][1],                                        'param',         'parameter type name is right');
$tdef_copy = {%$pchild};
$tdef_copy->{'parent'} = [@{$pchild->{'parent'}}];
($known, $open) = $ospace->resolve_names($tdef_copy);
is( $known,                                                    1,         'found parent name and resolved it');
is( $open,                                                     0,         'nothing else to resolve');
is( $ospace->need_resolve($tdef_copy),                         0,         'says "need_resolve" too');
is( ref $ospace->create_type($tdef_copy),                $pclass,         'type object created from resolved type definition');
$tdef_copy = {%$pchild};
$tdef_copy->{'parent'} = [@{$pchild->{'parent'}}];
is( ref $ospace->create_type($tdef_copy),                $pclass,         'type object created and resolved type definition');
@names = $ospace->add_type( $pchild );
is( int @names,                                                2,         'resolved def, created object, and registered type and parameter');
is( ref $names[0],                                       $pclass,         'right kind of type object was created');
is( ref $names[1],                                       'ARRAY',         'created type object has parametric ID');
is( $names[1][0],                              $pchild->{'name'},         'type object was created under right name');
is( $names[1][1],           $pchild->{'parent'}->parameter->name,         'type object was created with right parameter name');
is( $ospace->has_type( $pchild->{'name'}, $pchild->{'parent'}->parameter->name), 1, 'type indeed was registered');
@ID = $ospace->list_types( );
is( @ID,                                                       9,         'now 9 type ID base, parametric and its parameter');

@names = $ospace->need_resolve($nchild);
is( int @names,                                                1,         'parent of param type needs to be resolved');
is( ref $names[0],                                       'ARRAY',         'it is an param ID');
is( $names[0][0],                                  'simple_para',         'parametric type name is right');
is( $names[0][1],                                         'para',         'parent parameter name is right');
@names = $ospace->can_resolve($nchild);
is( int @names,                                                0,         'parent can not resolved (name of unknown type)');

@names = $ospace->need_resolve($param_name);
is( int @names,                                                1,         'param type with named parameter type, which needs resolve');
is( $names[0],                                           'value',         'parameter type name is right');
@names = $ospace->can_resolve($param_name);
is( int @names,                                                1,         'found parent ID can be resolved');
is( $names[0],                                           'value',         'it is an param ID');
$tdef_copy = {%$param_name};
($known, $open) = $ospace->resolve_names($tdef_copy);
is( $known,                                                    1,         'found parent name and resolved it');
is( $open,                                                     0,         'nothing else to resolve');
is( $ospace->need_resolve($tdef_copy),                         0,         'says "need_resolve" too');
is( ref $ospace->create_type($tdef_copy),                $pclass,         'type object created from resolved type definition');
$tdef_copy = {%$param_name};
is( ref $ospace->create_type($tdef_copy),                $pclass,         'type object created and resolved type definition');
@names = $ospace->add_type( $param_name );
is( int @names,                                                2,         'resolved def, created object, and registered type and parameter');
is( ref $names[0],                                       $pclass,         'right kind of type object was created');
is( ref $names[1],                                       'ARRAY',         'created type object has parametric ID');
is( $names[1][0],                          $param_name->{'name'},         'type object was created under right name');
is( $names[1][1],                                        'value',         'type object was created with right parameter name');
is( $ospace->has_type([ $param_name->{'name'}, 'value']),      1,         'type indeed was registered');
@ID = $ospace->list_types( );
is( @ID,                                                      10,         'now 10 types in open set');

@names = $ospace->need_resolve($param_parent);
is( int @names,                                                1,         'param type with named parameter type, which parent needs resolve');
is( $names[0],                                           'value',         'parameter type name is right');
@names = $ospace->can_resolve($param_parent);
is( int @names,                                                1,         'found parent ID can be resolved');
is( $names[0],                                           'value',         'it is an param ID');
$tdef_copy = {%$param_parent};
$tdef_copy->{'parameter'} = {%{$param_parent->{'parameter'}}};
($known, $open) = $ospace->resolve_names($tdef_copy);
is( $known,                                                    1,         'found parent name and resolved it');
is( $open,                                                     0,         'nothing else to resolve');
is( $ospace->need_resolve($tdef_copy),                         0,         'same result from methof "need_resolve"');
is( ref $ospace->create_type($tdef_copy),                $pclass,         'type object created from resolved type definition');
is( $ospace->has_type('pp_param'),                             0,         'but dependant types not registered');
$tdef_copy = {%$param_parent};
$tdef_copy->{'parameter'} = {%{$param_parent->{'parameter'}}};
my $type = $ospace->create_type($tdef_copy);
is( ref $type,                                           $pclass,         'type object created and resolved type definition');
is( $type->parameter->name,                           'pp_param',         'parameter got the right name');
@names = $ospace->add_type( $param_parent );
is( int @names,                                                3,         'resolved def, created object, and registered type and parameter');
is( ref $names[0],                                       $pclass,         'right kind of type object was created');
is( ref $names[1],                                       'ARRAY',         'created type object has parametric ID');
is( $names[1][0],                        $param_parent->{'name'},         'type object was created under right name');
is( $names[1][1],           $param_parent->{'parameter'}{'name'},         'type object was created with right parameter name');
is( $names[2],              $param_parent->{'parameter'}{'name'},         'type object was created under right name');
is( $ospace->has_type([ $param_parent->{'name'}, $param_parent->{'parameter'}{'name'}]),      1,        'type indeed was registered');
is( $ospace->has_type('pp_param'),                             1,         'but dependant types were now registered');
@ID = $ospace->list_types( );
is( @ID,                                                      12,         'now 12 types in open set');
#say " - $_" for $ospace->list_type_IDs( );

@names = $ospace->need_resolve($parent_param);
is( int @names,                                                2,         'param type with named parameter type and named parent');
is( $names[0],                                           'value',         'parameter type name is right');
is( $names[1],                                           'value',         'parent type name is right (and the same)');
@names = $ospace->can_resolve($parent_param);
is( int @names,                                                2,         'found parent ID can be resolved');
is( $names[0],                                           'value',         'it is an parent ID');
is( $names[1],                                           'value',         'it is an param ID');
$tdef_copy = {%$parent_param};
$tdef_copy->{'parameter'} = {%{$parent_param->{'parameter'}}};
($known, $open) = $ospace->resolve_names($tdef_copy);
is( $known,                                                    2,         'found parent name and resolved it');
is( $open,                                                     0,         'nothing else to resolve');
is( $ospace->need_resolve($tdef_copy),                         0,         'same result from methof "need_resolve"');
is( ref $ospace->create_type($tdef_copy),                $pclass,         'type object created from resolved type definition');
$tdef_copy = {%$parent_param};
$tdef_copy->{'parameter'} = {%{$parent_param->{'parameter'}}};
$type = $ospace->create_type($tdef_copy);
is( ref $type,                                           $pclass,         'type object created and resolved type definition');
is( $type->parameter->name,                          'ppp_param',         'parameter got the right name');
@names = $ospace->add_type( $parent_param );
is( int @names,                                                3,         'resolved def, created object, and registered type and parameter');
is( ref $names[0],                                       $pclass,         'right kind of type object was created');
is( ref $names[1],                                       'ARRAY',         'created type object has parametric ID');
is( $names[1][0],                        $parent_param->{'name'},         'type object was created under right name');
is( $names[1][1],           $parent_param->{'parameter'}{'name'},         'type object was created with right parameter name');
is( $names[2],              $parent_param->{'parameter'}{'name'},         'type object was created under right name');
is( $ospace->has_type([ $parent_param->{'name'}, $parent_param->{'parameter'}{'name'}]),      1,        'type indeed was registered');
is( $ospace->has_type('ppp_param'),                            1,         'but dependant types were now registered');
@ID = $ospace->list_types( );
is( @ID,                                                      14,         'now 14 types in open set');


$ospace->remove_type( 'array_ref' );
@names = $ospace->need_resolve($index_def);
is( int @names,                                                2,         'index of array ref references 2 types by name');
is( $names[0],                                         'int_pos',         'parent type name is right');
is( $names[1],                                       'array_ref',         'parameter type name is right (and the same)');
@names = $ospace->can_resolve($index_def);
is( int @names,                                                1,         'found parent ID can be resolved');
is( $names[0],                                         'int_pos',         'parent type name is right');
($known, $open) = $ospace->resolve_names($index_def);
is( $known,                                                    1,         'found parent name and resolved it');
is( $open,                                                     1,         'type: array_ref was deleted hence not resolvable');



# deleting types
is( $ospace->remove_type( $btype->name ),                 $btype,         'could remove basic type from namespace');
is( $ospace->has_type( $btype->name ),                         0,         'type object is gone from namespace');
is( $ospace->get_type( $btype->name ),                     undef,         'and its no longer retrievable');
is( $ospace->remove_type( [$ptype->name,$ptype->parameter->name] ), $ptype,  'could remove parametric type from namespace');
is( $ospace->has_type( $ptype->name ),                         0,         'type object is gone from namespace');
is( $ospace->get_type( $ptype->name ),                     undef,         'and its no longer retrievable');
@names = $ospace->can_resolve($param_name);
is( int @names,                                                0,         'can not resolve type names of deleted types');




exit 0;

__END__
add param type defs
replace them
reference deleted

both

my $para   = {name => 'simple_para', help => 'help', code => 1, default => 1, parameter => { name => 'param',  help => 'help', code => 1, default => 1, }};
my $bchild = {name => 'sb_child', help => 'help', code => 2, default => 2, parent => 'value', parameter => { name => 'param',  help => 'help', code => 1, default => 1, }};
my $pchild = {name => 'sp_child', help => 'help', code => 3, default => 3, parent => ['simple_param', 'param']};
my $nchild = {name => 'sn_child', help => 'help', code => 4, default => 4, parent => ['simple_param', 'para']};

my $param_name  = {name => 'sp_para', help => 'help', code => 5, default => 5, parameter => 'value'};
my $param_parent ={name => 'spp_para', help => 'help', code => 6, default => 6, parameter => { name => 'pp_param', help => 'help', code => 6.5, parent => 'value'}};
my $parent_param ={name => 'sppp_para', help => 'help', code => 7, default => 7, parent => 'value', parameter => { name => 'ppp_param', help => 'help', code => 5, parent => 'value'}};


my $index_def= { name=> 'index',  help=> 'valid index of array',code=> 'return "value $value is out of range" if $value >= @$param', symbol => 'I', 
                     parent=> 'int_pos',  parameter => {   name => 'array',  parent=> 'array_ref', default=> [1] }, };

#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Basic;       my $bclass  = 'Kephra::Base::Data::Type::Basic';
use Kephra::Base::Data::Type::Parametric;  my $pclass  = 'Kephra::Base::Data::Type::Parametric';
                                           my $sclass  = 'Kephra::Base::Data::Type::Namespace';

my $val_def = { name=> 'value',  help=> 'defined value',    code=> 'defined $value',                            default=> '',     };
my $nref_def = {name=> 'no_ref', help=> 'not a reference',  code=> 'not ref $value',        parent=> 'value',              , symbol => '$'};
my $int_def = { name=> 'int',    help=> 'integer',          code=> 'int($value) eq $value', parent=> 'no_ref',  default=> 0, symbol => 'N'};
my $ip_def =  { name=> 'int_pos',help=> 'greater equal zero',code=>'$value >= 0',           parent=> 'int'};
my $aref_def = {name=> 'array_ref', help=> 'array reference',code=> q/ref $value eq 'ARRAY'/,                   default=> []};
my $nea_def = {name=> 'nemty_array', help=> 'array with content', code=> '@$value',         parent => 'array_ref', default=> [1]};
my $index_def ={name => 'index', help=> 'valid index of array',code=> 'return "value $value is out of range" if $value >= @$param', symbol => 'I', 
                     parent=> 'int_pos',  parameter => {   name => 'array',  parent=> 'array_ref', default=> [1] }, };
my $dindex_def ={name => 'index', help=> 'valid index of array',code=> 'return "value $value is out of range" if $value >= @$param', symbol => 'I', 
                     parent=> 'int_pos',  parameter => 'nemty_array'} ;
my $simple_para = {name => 'simple_para', help => 'help', code => 1, default => 1, parameter => { name => 'name',  help => 'help', code => 1, default => 1, }};

package NameSpaceTester; 
use Test::More tests => 300;

eval "use $sclass;";
is( $@, '',                                                               'loaded namespace package');


my $space = Kephra::Base::Data::Type::Namespace->new();
is( ref $space, $sclass,                                                  'could create a closable type namespace object');
is( $space->list_type_names('basic'),                      undef,         'no basic types can be listed');
is( $space->list_type_names('param'),                      undef,         'no parametric types can be listed');
is( $space->list_symbols('basic'),                         undef,         'no basic symbols can be listed');
is( $space->list_symbols('param'),                         undef,         'no parametric symbols can be listed');
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


my $ospace = Kephra::Base::Data::Type::Namespace->new('open');
is( ref $ospace, $sclass,                                                 'could create an unclosable type namespace object');
is( $ospace->is_open(),                                        1,         'newly made type namespace is open');
is( $ospace->close(),                                          0,         'could not close namespace');
is( $ospace->is_open(),                                        1,         'open type namespace is still open');


my $btype = $space->create_type($val_def);
is( ref $btype,                                         $bclass ,         'could create simple basic type without deps');
my $ptype = $space->create_type($simple_para);
is( ref $ptype,                                         $pclass ,         'could create simple parametric type without deps');
is($space->need_resolve($val_def),                             0,         'nothing to resolve in simple basic type definition');
is($space->need_resolve($simple_para),                         0,         'nothing to resolve in simple parametric type definition');
is($space->can_resolve($val_def),                              0,         'not need to resolve in simple basic type definition');
is($space->can_resolve($simple_para),                          0,         'not need to resolve in simple parametric type definition');


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
my @names = $ospace->list_type_names('basic');
is( int @names,                                                1,         'only one basic type was stored');
is( $names[0],                                      $btype->name,         'listed its name right');
@names = $ospace->list_type_names('param');
is( int @names,                                                1,         'only one parametric type was stored');
is( $names[0],                                      $ptype->name,         'listed its name right');
@names = $ospace->list_type_names('param', 'simple_para');
is( int @names,                                                1,         'only one sub type of parametric type was stored');
is( $names[0],                           $ptype->parameter->name,         'listed its name right');
my @symbols = $ospace->list_symbols('basic');
is( int @symbols,                                              0,         'no basic type symbols was stored yet');
@symbols = $ospace->list_symbols('param');
is( int @symbols,                                              0,         'no parametric type symbols was stored yet');
is( $ospace->remove_type( $btype->name ),                 $btype,         'could remove basic type from namespace');
is( $ospace->has_type( $btype->name ),                         0,         'type object is gone from namespace');
is( $ospace->get_type( $btype->name ),                     undef,         'and its no longer retrievable');
is( $ospace->remove_type( [$ptype->name,$ptype->parameter->name] ), $ptype,  'could remove parametric type from namespace');
is( $ospace->has_type( $btype->name ),                         0,         'type object is gone from namespace');
is( $ospace->get_type( $btype->name ),                     undef,         'and its no longer retrievable');


exit 0;

__END__

add type defs
replace them
symbols
reject ownership

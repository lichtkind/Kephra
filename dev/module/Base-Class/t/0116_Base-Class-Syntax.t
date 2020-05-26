#!/usr/bin/perl -w
use v5.14;
use warnings;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class;

class Kephra::C

type cs => {help => 'a few c', check => sub { length $_[0] < 6}, parent => 'c+'}
type c+ => {help => 'bunch of c', check => sub { $_[0] =~ /^c+$/ }, parent => 'str'}

parameter subtype even => {parent => 'int', default => 2, check => ['is even' => sub {not $_[0] % 2}]}

        method str  () {'str'}
public  method pstr () {'pstr'}
private method one  () {1}

multi method double (int a) {2}
multi method double (str a) {1}

      method retstr  (--> str) { 'str' }
      method nretstr (--> str) { [] }
      method numonly (num   i) { 'good' }
      method ret     (str val) { $_[1]->val }

      method run (int d - int a --> str) { my ($self, $param) = @_; return 'run' }

public multi method do (int d - even nr --> str) { 2 }
private multi method do (str d - even nr --> str) { 1 }


getter method  geta     ()      { $_[2]->get           / 2   }
setter method  seta     (int i) { $_[2]->set( $_[1]->i * 2 ) }
       method setabeta  (even e){ $_[0]->abeta($_[1]->e); $_[0]->abeta()}

attribute a => {help => 'text', type => 'even', required => 0,
                get  => {-ageta => 'public', -abeta => 'private', geta => 'public'},
                set  => {-aseta => 'public', -abeta => 'access',  seta => 'public'},} 

class Kephra::D

object attribute b => {class => 'Kephra::C', help => 'help', 
                      delegate => { -getb => {scope => 'public', rename => 'ageta'},
                                    -setb => {scope => 'public', rename => 'aseta'} }}

package main;
use Test::More tests => 53;
my ($obj, $c, $d);
my $v = 0;
my $pobj = bless \$v, 'Kephra::C::PRIVATE';

ok( ($obj = Kephra::C->new()),                   'object with class syntax created');
is( ref $obj,     'Kephra::C',                   'object is of right class');
ok( Kephra::Base::Data::Type::is_known('c+'),    'created own type');
ok( Kephra::Base::Data::Type::check('c+','ccc')eq'', 'accepted correctly data on own type c+');
ok( Kephra::Base::Data::Type::check('c+','cdc')    , 'rejected correctly data on own type c+');
ok( Kephra::Base::Data::Type::check('cs','ccc')eq'', 'accepted correctly data on own derived type cs');
ok( Kephra::Base::Data::Type::check('cs','cccccc'),  'rejected correctly data on own derived type cs');
is( ref $obj->can('str'),                'CODE', 'normal method was created');
is( $obj->str(),                          'str', 'normal method returns right result');
ok( not($$obj),                                , 'got no error message');
is( ref $obj->can('pstr'),               'CODE', 'explicitly public method was created');
is( $obj->pstr(),                        'pstr', 'method was created');
is( $obj->can('one'),                     undef, 'private method "one" is not public');
is( ref $pobj->can('one'),               'CODE', 'private method "one" detected');
is( $pobj->one(),                         undef, 'private method "one" returns right result'); # undef because not registered
is( $obj->retstr(),                       'str', 'return type checks let pass right value');
isnt( ref $obj->nretstr(),              'ARRAY', 'return type checks rejected wrong value');
is( $obj->str(1),                         undef, 'rejected too much parameter');
ok( $$obj,                                     , 'got error message');
is( $obj->ret(),                          undef, 'rejected too few parameter');
ok( $$obj,                                     , 'got error message');
is( $obj->numonly('d'),                   undef, 'rejects wrong input type in parameter');
is( $obj->numonly(2),                    'good', 'accepts right data type in parameter ');
is( $obj->double('d'),                        1, 'multi method dispatch works in first variant');
is( $obj->double(2),                          2, 'multi method dispatch works in second variant');
is( $obj->ret(3),                             3, 'get return value / parameter propagation works');

is( $obj->run(),                          undef, 'method with optional params gets not enough params');
is( $obj->run(1,2,3),                     undef, 'method with optional params gets too much params');
is( $obj->run(3),                         'run', 'method with optional params gets required amount');
is( $obj->run(3,4),                       'run', 'method with optional params gets maximal amount');

is( $obj->ageta(),                            2, 'autogenerated getter gives right default value');
is( $obj->aseta(4),                           4, 'autogenerated setter works');
is( $obj->ageta(),                            4, 'autogenerated getter works');
is( $obj->aseta(5),                       undef, 'autogenerated setter rejects value of wrong type');
is( $obj->ageta(),                            4, 'autogenerated getter still has last correct value');

is( $obj->seta(5),                           10, 'hand crafted setter can be called');
is( $obj->ageta(),                           10, 'correct value was written');
is( $obj->geta(),                             5, 'hand crafted getter can be called');

is( $obj->can('abeta'),                   undef, 'private getter/setter is not publicly visible');
is( $obj->setabeta(12),                      10, 'can not use the access scoped setter in private scope but getter');
is( $obj->ageta(),                           10, 'correct value was written');

ok( ($c = Kephra::C->new({a => 6}))            , 'object created with parameter mapping in constructor');
is( ref $c,     'Kephra::C',                     'object is of right class');
is( $c->ageta(),                              6, 'parameter mapping worked');

ok( ($c = Kephra::C->new({seta => [6]}))       , 'object created with parameter mapping in constructor');
is( ref $c,     'Kephra::C',                     'object is of right class');
is( $c->ageta(),                              12, 'parameter mapping worked');

ok( ($d = Kephra::D->new()),                   'second object with class syntax created');
is( ref $d,     'Kephra::D',                   'object is of right class');
is( ref $d->can('getb'),               'CODE', 'auto delegator was created');
is( $d->getb(),                             2, 'delegate attribute default value');
is( $d->setb(4),                            4, 'delegate setter call');
is( $d->getb(),                             4, 'new attrib value was set');



exit 0;
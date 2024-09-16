#!/usr/bin/perl -w
use v5.14;
use warnings;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class;

my $p = \&Kephra::Base::Class::Method::Signature::parse;
my $m = \&Kephra::Base::Class::Builder::make;

$m->('class',  'Kephra::C');
$m->('type',   'Kephra::C', 'c+', {help => 'bunch of c', check => sub { $_[0] =~ /^c+$/ }, parent => 'str'});
$m->('method', 'Kephra::C', 'str', $p->(''), sub {'str'}, {});
$m->('method', 'Kephra::C', 'pstr', $p->(''), sub {'pstr'}, {});
$m->('method', 'Kephra::C', 'one', $p->(''), sub {1},{private => 1});
$m->('method', 'Kephra::C', 'callone', $p->(''), sub {$_[0]->one}, {});
$m->('method', 'Kephra::C', 'retstr', $p->('--> str'), sub {'str'}, {});
$m->('method', 'Kephra::C', 'nretstr', $p->('--> str'), sub {[]}, {});
$m->('method', 'Kephra::C', 'run', $p->('int d - int a --> str'), 
               sub{my ($self, $param) = @_;my $ret = 'run'.$param->d; $ret .= $param->a if defined $param->a; $ret}, {});
$m->('finalize', 'Kephra::C');


package main;

use Test::More tests => 25;
my $obj;
my $v = 0;
my $pobj = bless \$v,                            'Kephra::C::PRIVATE';
ok( ($obj = Kephra::C->new()),                   'object with class syntax created');
is( ref $obj,                                    'Kephra::C', 'object is of right class');
ok( Kephra::Base::Data::Type::is_known('c+')   , 'created own type');
ok( Kephra::Base::Data::Type::check('c+','ccc')eq'','own type works');
is( ref $obj->can('str'),                'CODE', 'normal method was created');
is( $obj->str(),                          'str', 'normal method returns right result');
is( ref $obj->can('pstr'),               'CODE', 'explicitly public method was created');
is( $obj->pstr(),                        'pstr', 'method was created');
is( $obj->can('one'),                     undef, 'private method "one" is not public');
is( ref $pobj->can('one'),               'CODE', 'private method "one" detected');
is( $pobj->one(),                         undef, 'private method "one" returns right result');  # undef because not registered obj
is( $obj->callone(),                          1, 'private method "one" can be called in the class');
is( $obj->retstr(),                       'str', 'return type checks let pass right value');
isnt( ref $obj->nretstr(),              'ARRAY', 'return type checks rejected wrong value');
is( $obj->run(),                          undef, 'not enough parameter for method "run"');
is( $obj->run(1,2,3),                     undef, 'too much parameter for method "run"');
is( $obj->run(1),                       'run10', 'just required parameter of method "run" are enough');
is( $obj->run(1,2),                     'run12', 'required and optional parameter of methof "run" landed');
is( $obj->run({d => 1}),                 'run1', 'just required parameter as input hash');
is( $obj->run({d => 1, a => 2}),        'run12', 'required and optional parameter as input hash');
is( $obj->run({a => 2}),                  undef, 'optional parameter was missing');
is( $obj->run('da'),                      undef, 'type error of required parameter');
is( $obj->run(1,[]),                      undef, 'type error of optional parameter');
is( $obj->run({d => 'da'}),               undef, 'type error of required parameter in input hash');
is( $obj->run({d=>1,a => []}),            undef, 'type error of optional parameter in input hash');


exit 0;
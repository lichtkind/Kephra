#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 32;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class;

my $ts = Kephra::Base::Class::Type->new('classname');
my $even = 'even';
my $evendef = {check => ['is even' => sub {not $_[0] % 2}], parent => 'int', default => 2};
my $seven = 'smalleven';
my $sevendef = {check => ['small enough' => sub {$_[0] < 10}], parent => 'even'};
my $l = my @l = Kephra::Base::Data::Type::list();

is( ref $ts,                                   'Kephra::Base::Class::Type', 'created class type object');
is( scalar(my @a = $ts->list()) ,          $l, 'no types there yet');
cmp_ok( $ts->is_known($even),         '==', 0, 'not even our special type');
cmp_ok( $ts->delete($even),           '==', 0, 'none existing type can not be deleted');

cmp_ok( $ts->is_known('int'),         '==', 1, 'knows default types');
is( $ts->default_value('int'),              0, 'knows default value of default types');
cmp_ok( $ts->add($even, $evendef),    '==', 1, 'type created');
is( scalar(@a = $ts->list()) ,           $l+1, 'now there is one more type');
ok( $even ~~ [$ts->list()],                  , 'our type was registered');
cmp_ok( $ts->is_known($even),         '==', 1, 'now our special type is there');
cmp_ok( $ts->default_value($even),    '==', 2, 'set default value correctly');
like( $ts->check($even,'a',{}),    qr/number/, 'check rejected not number');
like( $ts->check($even,1.1,{}),   qr/integer/, 'check rejected not number');
like( $ts->check($even,1,{}),     qr/is even/, 'check rejected not even number');
is( $ts->check($even,2,{}),                '', 'check accepted even number');
is( ref $ts->delete($even),            'HASH', 'our type was deleted');
cmp_ok( $ts->is_known($even),         '==', 0, 'our special type is gone');
is( scalar(@a = $ts->list()) ,             $l, 'no types there again');

cmp_ok( $ts->add($even, $evendef),    '==', 1, 'type created again');
cmp_ok( $ts->add($seven, $sevendef),  '==', 1,'second type created');
cmp_ok( $ts->is_known($seven),        '==', 1, 'now our derived type is known');
cmp_ok( $ts->default_value($seven),   '==', 2, 'imported default value from parent correctly');
is( scalar(@a = $ts->list()) ,           $l+2, 'two types registered');
ok( $seven ~~ [$ts->list()],                 , 'new type type registered');

is( ref $ts->delete($even),            'HASH', 'can delete derived type because checks were cloned from parent');
like( $ts->check($seven,'a',{}),   qr/number/, 'check rejected not number as derived type');
like( $ts->check($seven,1,{}),    qr/is even/, 'check rejected not even number as derived type');
like( $ts->check($seven,22,{}), qr/small enough/, 'check rejected too large number as derived type');
is( $ts->check($seven,2,{}),               '', 'check accepted even number');
is( ref $ts->delete($seven),           'HASH', 'derived type was deleted');
cmp_ok( $ts->is_known($seven),        '==', 0, 'derived type is gone');
is( scalar(@a = $ts->list()) ,             $l, 'no types there again');


#cmp_ok( $ts->add($even, 'int', $even, 1),'==', 0, 'can not create type where default is outside accepted set');
exit 0;

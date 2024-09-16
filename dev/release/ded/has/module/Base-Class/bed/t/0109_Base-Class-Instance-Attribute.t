#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 38;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Attribute::Type;

my $atype = Kephra::Base::Class::Attribute::Type->new();
my $even = 'even';
my $evendef = {check => ['is even' => sub {not $_[0] % 2}], parent => 'int', default => 2};
my $seven = 'smalleven';
my $sevendef = {check => ['small enough' => sub {$_[0] < 10}], parent => 'even'};
my $l = my @l = Kephra::Base::Data::Type::list_names();

is( ref $atype,                                   'Kephra::Base::Class::Attribute::Type', 'created class type object');
is( scalar(my @a = $atype->list_names()) ,    $l, 'no types there yet');
cmp_ok( $atype->is_known($even),         '==', 0, 'not even our special type');
cmp_ok( $atype->delete($even),           '==', 0, 'none existing type can not be deleted');

cmp_ok( $atype->is_known('int'),         '==', 1, 'knows default types');
is( $atype->get_default_value('int'),          0, 'knows default value of default types');

cmp_ok( $atype->add($even, $evendef),    '==', 1, 'type created');
is( scalar(@a = $atype->list_names()),      $l+1, 'now there is one more type');
ok( $even ~~ [$atype->list_names()],            , 'our type was registered');
cmp_ok( $atype->is_known($even),         '==', 1, 'now our special type is there');
cmp_ok( $atype->get_default_value($even),    '==', 2, 'set default value correctly');
like( $atype->check($even,'a',{}),    qr/number/, 'check rejected value: not number');
like( $atype->check($even,1.1,{}),   qr/integer/, 'check rejected value: not number');
like( $atype->check($even,1,{}),     qr/is even/, 'check rejected value: not even number');
is(   $atype->check($even,2,{}),              '', 'check accepted even number');
is( ref $atype->delete($even),            'HASH', 'our type was deleted');
cmp_ok( $atype->is_known($even),         '==', 0, 'our special type is gone');
is( scalar(@a = $atype->list_names()) ,       $l, 'no types there again');

cmp_ok( $atype->add($even, $evendef),    '==', 1, 'type created again');
cmp_ok( $atype->add($seven, $sevendef),  '==', 1,'second type created');
cmp_ok( $atype->is_known($seven),        '==', 1, 'now our derived type is known');
cmp_ok( $atype->get_default_value($seven),'==',2, 'imported default value from parent correctly');
is( scalar(@a = $atype->list_names()) ,     $l+2, 'two types registered');
ok( $seven ~~ [$atype->list_names()],           , 'new type type registered');

my $cb = $atype->get_callback($even);
is( ref $cb,                           'CODE', 'got callback');
like( $cb->('a',{}),               qr/number/, 'callback rejected value: not number');
like( $cb->(1.1,{}),              qr/integer/, 'callback rejected value: not number');
like( $cb->(1,{}),                qr/is even/, 'callback rejected value: not even number');
is(   $cb->(2,{}),                         '', 'callback accepted even number');

is( ref $atype->delete($even),            'HASH', 'can delete derived type because checks were cloned from parent');
like( $atype->check($seven,'a',{}),   qr/number/, 'check rejected not number as derived type');
like( $atype->check($seven,1,{}),    qr/is even/, 'check rejected not even number as derived type');
like( $atype->check($seven,22,{}),qr/small enough/,'check rejected too large number as derived type');
is( $atype->check($seven,2,{}),               '', 'check accepted even number');
is( ref $atype->delete($seven),           'HASH', 'derived type was deleted');
cmp_ok( $atype->is_known($seven),        '==', 0, 'derived type is gone');
is( scalar(@a = $atype->list_names()) ,       $l, 'no types there again');
cmp_ok( $atype->add($even, 'int', $even, 1),'==', 0, 'can not create type where default is outside accepted set');

exit 0;

#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 20;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Data qw/clone_data/;
use TestClass;


is( clone_data(1.5),                     1.5, 'cloned number');
is( clone_data('string'),           'string', 'cloned string');

my $ref = \7.5;
my $clone = clone_data($ref);
isnt( $clone,                      $ref, 'clone has different ref');
is( ref $clone,                ref $ref, 'clone ref has same type');
is( $$clone,                      $$ref, 'scalar clone has same size');

$ref = \\11.4;
$clone = clone_data($ref);
isnt( $clone,                      $ref, 'clone has different ref');
is( ref $clone,                ref $ref, 'clone ref has same type');
is( ref $$clone,              ref $$ref, 'clone referencing same ref type');
is( $$$clone,                    $$$ref, 'double refed scalar value is same in clone');

$ref = [1,2,3];
$clone = clone_data($ref);
isnt( $clone,                      $ref, 'clone has different ref');
is( ref $clone,                ref $ref, 'clone ref has same type');
is( $#$clone,                    $#$ref, 'array clone has same size');
is( $clone->[0],              $ref->[0], 'array clone has same first value');
is( $clone->[1],              $ref->[1], 'array clone has same second value');
is( $clone->[2],              $ref->[2], 'array clone has same third value');

$ref = {1 => 2 , 3 => 'string'};
$clone = clone_data($ref);
isnt( $clone,                      $ref, 'clone has different ref');
is( ref $clone,                ref $ref, 'clone ref has same type');
is( keys %$clone,            keys %$ref, 'hash clone has same size');
is( $clone->{1},              $ref->{1}, 'hash clone has same first value');
is( $clone->{3},              $ref->{3}, 'hash clone has same first value');


exit 0;


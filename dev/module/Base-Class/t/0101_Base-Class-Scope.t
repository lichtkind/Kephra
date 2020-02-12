#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Scope;

ok(1,'good');

#cmp_ok( $ts->add($even, 'int', $even, 1),'==', 0, 'can not create type where default is outside accepted set');
exit 0;

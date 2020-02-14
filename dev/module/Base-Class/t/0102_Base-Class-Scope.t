#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Scope;

#
my @mscopes = Kephra::Base::Class::Scope::list_method_names();
my @scopes = Kephra::Base::Class::Scope::list_method_names();

# m is subset
# alle level in m are diff
# construct 0..4 el path
# construct mit illegalen scope
# thighter scope hat mehr included names 

ok(1,'good');

#cmp_ok( $ts->add($even, 'int', $even, 1),'==', 0, 'can not create type where default is outside accepted set');
exit 0;

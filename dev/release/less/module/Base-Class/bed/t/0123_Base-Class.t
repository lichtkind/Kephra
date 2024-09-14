#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class;

my $ts = Kephra::Base::Class::Type->new('classname');


is( ref $ts,                                   'Kephra::Base::Class::Type', 'created class type object');



exit 0;

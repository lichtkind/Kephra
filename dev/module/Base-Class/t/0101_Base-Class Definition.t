#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Definition;

my $class = 'Kephra::Base::Class::Definition';

my $def = Kephra::Base::Class::Definition->new('C');


is( ref $def,        $class, 'created class definition object');



exit 0;

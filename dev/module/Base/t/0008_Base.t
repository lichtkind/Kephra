#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 4;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base qw/:all/;

my $cc = new_counter();
my $cc2 = new_counter();
my $clos = 'Kephra::Base::Closure';
is(ref $cc, '$clos',    'created counter by shortcut sub');
is($cc->run(), 0,       'counter works');
is($cc->run(), 1,       'as it should');
is($cc2->run(), 0,      'independent from other counter');

exit 0;


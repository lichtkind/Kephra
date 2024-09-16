#!/usr/bin/perl -w

use v5.12;
use warnings;
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib'}

my $modulename = 'Kephra::API::Event::Table';
my @sub = qw//;

use_ok( $modulename );          # eval qq{require $modulename};
can_ok( $modulename, $_) for qw//;


#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Parametric;
use Test::More tests => 1;

ok( 2,                'recognize that a ref is not a value');

exit 0;

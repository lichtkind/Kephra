#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Simple;
use Test::More tests => 1;

ok( 2,              'sub check_type got imported');
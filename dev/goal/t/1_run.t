#!/usr/bin/perl -w

use v5.16;
use warnings;
use Test::Script;
use Test::More tests => 2;

BEGIN { unshift @INC, 'lib'}

use_ok( 'Kephra' );      
script_compiles('bin/kephra.pl');

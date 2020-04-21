#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base;

ok(1, 'these  test follow in later modules');

exit 0;


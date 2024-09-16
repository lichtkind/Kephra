#!/usr/bin/perl -w
use v5.14;
use warnings;
use Scalar::Util qw(blessed);
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API::Class::Attribute;

ok(1,'ok');

exit 0;

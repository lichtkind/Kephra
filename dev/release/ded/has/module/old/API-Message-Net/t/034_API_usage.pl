#!/usr/bin/perl -w
use v5.14;
use warnings;
use Scalar::Util qw(blessed);
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API;

my (@warning, @error, @note, @report);
my ($class, $item_class, @a) = ('Kephra::API::Object::Store', 'TestClass');
no strict 'refs';
no warnings 'redefine';
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
use strict;
use warnings;

#my $obj = Kephra::API::Object->new();
#is( blessed($obj),                                $obj, 'created a base object');

ok(1,'one');

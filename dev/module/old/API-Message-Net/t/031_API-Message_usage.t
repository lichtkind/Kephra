#!/usr/bin/perl -w
use v5.14;
use warnings;
use Scalar::Util qw(blessed);
use Test::More tests => 1;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API::Message;

my (@warning, @error, @note, @report);
my ($class, $item_class, $ID, $item, @a) = ('Kephra::API::Message', 'TestClass');
no strict 'refs';
no warnings 'redefine';
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
use strict;
use warnings;

#sub_caller
# my ($file, $line, $sub, $package) = Kephra::API::Message::sub_caller(2);

#is( blessed($msg),                            $class, 'created a store object');

ok(1, 'one');

exit(0);
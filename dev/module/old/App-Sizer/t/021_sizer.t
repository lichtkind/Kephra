#!/usr/bin/perl -w

use v5.12;
use warnings;
use Test::More tests => 5;

my $modulename = 'Kephra::App::Sizer';
BEGIN { unshift @INC, 'lib', '../lib'}

require_ok( 'Wx' );             # requesits
use_ok( $modulename );          # eval qq{require $modulename};
new_ok( $modulename );
can_ok( $modulename, $_) for qw/                          prepend append/;


###### catching the warning output ######
my $warnmsg = '';

# SKIP: {};
# TODO: {};

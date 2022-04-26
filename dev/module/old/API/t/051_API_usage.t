#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 22;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API;

my (@warning, @error, @note, @report);
my ($class) = ('Kephra::API');
no strict 'refs';
no warnings 'redefine';
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
use strict;
use warnings;

package TestPackage;
sub caller_check      { Kephra::API::sub_caller() }
sub deep_caller_check { Kephra::API::sub_caller(2) }

package TestIntermediatory;
sub _helper           { TestPackage::caller_check() }
sub call_relay        { TestPackage::deep_caller_check() }

package Kephra::API;
sub call_relay        { TestPackage::caller_check() }

package TestCaller;
sub normal_call       { TestPackage::caller_check()  }
sub helper_call       { TestIntermediatory::_helper()  }
sub deep_call         { TestIntermediatory::call_relay() }
sub api_call          { Kephra::API::call_relay() }

package main;
my ($file, $line, $sub, $package) = TestCaller::normal_call();
is($file,            __FILE__, 'got simple caller file right');
is($line,                  32, 'got simple caller file number right');
is($sub,        'normal_call', 'got simple caller sub name right');
is($package,     'TestCaller', 'got simple caller package name right');

($file, $line, $sub, $package) = TestCaller::helper_call();
is($file,            __FILE__, 'got helper caller file right');
is($line,                  33, 'got helper caller file number right');
is($sub,        'helper_call', 'got helper caller sub name right');
is($package,     'TestCaller', 'got helper caller package name right');

($file, $line, $sub, $package) = TestCaller::deep_call();
is($file,            __FILE__, 'got deep caller file right');
is($line,                  34, 'got deep caller file number right');
is($sub,          'deep_call', 'got deep caller sub name right');
is($package,     'TestCaller', 'got deep caller package name right');

($file, $line, $sub, $package) = TestCaller::api_call();
is($file,            __FILE__, 'got API caller file right');
is($line,                  35, 'got API caller file number right');
is($sub,           'api_call', 'got API caller sub name right');
is($package,     'TestCaller', 'got API caller package name right');

my ($date1, $time1) = Kephra::API::date_time();
my ($date2, $time2) = Kephra::API::date_time();
$date1 =~ s/\.//g;  $date2 =~ s/\.//g;
$time1 =~ s/://g;  $time2 =~ s/://g;

is(($time1 <= $time2),           1, 'time stamps are in order');
is((($date1 == $date2) or ($date1 == $date2)), 1, 'date stamps are in order');

my $counter = Kephra::API::create_counter();
is( Kephra::API::is_call($counter),  1, 'counter is a Kephra call');
is( $counter->run(),                 0, 'counter starts at 0');
is( $counter->run(),                 1, 'counter can count');
is( $counter->run(),                 2, 'counter can count');

exit(0);
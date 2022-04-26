#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 28;

BEGIN { unshift @INC, 'lib', '../lib'}
use Kephra::API::Call;

my (@warning, @error, @note, @report);
my ($class, $name) = ('Kephra::API::Call', 'name');

no strict 'refs';
no warnings 'redefine';
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
use strict 'refs';
use warnings;

my ($source, $active) = ('"txt"', 0);
my $call = Kephra::API::Call->new($name, $source, $active);

is( ref $call,              $class, 'call created');
is( Kephra::API::is_call($call), 1, 'call object recognized by central API');
is( $call->source(),       $source, 'got source right');
is( $call->name(),           $name, 'got name right');
is( $call->is_active(),    $active, 'got state right');
is( $call->run(),            undef, 'got result right, did not run');
is( $call->set_active(1),        1, 'changed state');
is( $call->is_active(),          1, 'state change was sucess');
is( $call->set_active(0),        0, 'changed state to passive');
is( $call->is_active(),          0, 'state change was sucess');
$call->set_active(1);
is( $call->run(),            'txt', 'got result right, did run');
#like( pop(@note),        qr/$name/, 'latest run was noted');

$call = Kephra::API::Call->new($name, $source, 1);
is( $call->run(),            'txt', 'created active call this time');

$call = Kephra::API::Call->new( '', $source );
is( $call->run(),            'txt', 'right state default');
is( $call->is_active(),          1, 'calls run by defaults');
is( $call->name(),              '', 'right default name');

$call = Kephra::API::Call->new('', '$_[0]+1');
is( ref $call,              $class, 'second call created');
is( $call->run(3),               4, 'ran and got right result');

my $status = Kephra::API::Call->new( $name, $source, $active)->status();
like( $status,          qr/active/, 'call state has to be in his status report');
like( $status,         qr/$source/, 'call source has to be in his status report');
like( $status,           qr/$name/, 'call name has to be in his status report');

# error msg
is( Kephra::API::Call->new(1),                         undef, 'no call created with missing params');
like( pop(@error),                qr/two to three parameter/, 'produced right error message for not enough params');
is( Kephra::API::Call->new($source, $name, $active,1), undef, 'no call created with too many params');
like( pop(@error),                qr/two to three parameter/, 'right error message for too many params');
is( Kephra::API::Call->new('','txt'),                  undef, 'no call created with bad code');
like( pop(@error),                      qr/not be evaluated/, 'error message for bad code');
is( $call->set_active(),                               undef, 'no state chane with no parameter');
like( pop(@error),                   qr/need only a boolean/, 'error message for not enough params on set active');

exit 0;

;

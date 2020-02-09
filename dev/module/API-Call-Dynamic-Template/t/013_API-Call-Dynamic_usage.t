#!/usr/bin/perl -w
use v5.14;
use warnings;
use Test::More tests => 51;

BEGIN { unshift @INC, 'lib', '../lib', 't', '.'}
use TestClass;
use Kephra::API::Call::Dynamic;

my (@warning, @error, @note, @report);
my ($class, $parent, $name) = ('Kephra::API::Call::Dynamic', 'Kephra::API::Call', 'name');

no strict 'refs';
no warnings 'redefine';
*{$parent.'::error'}  = sub {push @error,  shift; undef };
*{$parent.'::warning'}= sub {push @warning,shift; undef };
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
use strict;
use warnings;

my ($source, $active, $ref) = ('$ref->{1}', 0, {1 => 2});
my $call = Kephra::API::Call::Dynamic->new($name, $ref, $source, $active);

# basics getter
is( ref $call,              $class, 'call created');
is( Kephra::API::is_call($call), 1, 'dynacall object recognized by central API as call');
is( Kephra::API::is_dynacall($call), 1, 'dynacall object recognized by central API as dynacall');
is( $call->name(),           $name, 'got name of dyna call');
is( $call->ref_type(),      'HASH', 'got ref type of dyna call');
is( $call->source(),       $source, 'got source of dyna call');
is( $call->is_active(),    $active, 'got state of dyna call');
is( $call->get_reference(),   $ref, 'got ref of dyna call');
is( $call->run(),            undef, 'right result because could not run, call created inactive');

# getter/setter: active
is( $call->set_active(1),        1, 'changed state');
is( $call->is_active(),          1, 'state change was sucess');
is( $call->set_active(0),        0, 'changed state to passive');
is( $call->is_active(),          0, 'state change was sucess again');
$call->set_active(1);
is( $call->run(),                2, 'got result right, did run');
#like( pop(@note),        qr/$name/, 'latest run was noted');

$call = Kephra::API::Call::Dynamic->new($name, $ref, $source, 1);
is( $call->run(),                2, 'created active dyna call');
is( $call->is_active(),          1, 'dyna call knows he is active');

$call = Kephra::API::Call::Dynamic->new( '', $ref, $source );
is( $call->run(),                2, 'dyna call run by default');
is( $call->is_active(),          1, 'dyna calls are active by default');
is( $call->name(),              '', 'works with empty names too');

# getter/setter: ref
$ref = {1 => 4};
is( $call->run(),                 2, 'stored ref is independent');
is( $call->set_reference($ref),$ref, 'set new call ref');
is( $call->get_reference(),    $ref, 'new ref was successful set');
is( $call->run(),                 4, 'good run with new ref');
is( $call->set_reference([]), undef, 'blocked wrong ref type');
like( pop(@error),  qr/not of type/, 'try to set bad ref produced error message');

$ref = TestClass->new(5);
$call = Kephra::API::Call::Dynamic->new( $name, $ref, '$ref->init();' );
is( ref $call,              $class, 'created call with object as ref type');
is( $call->ref_type(),    ref $ref, 'class is ref type');
is( $call->get_reference(),   $ref, 'object ref was stored');
is( $call->run(),                5, 'good run with object ref');

$ref->set(6);
$call = Kephra::API::Call::Dynamic->new( $name, $ref, '$ref->set( shift );' );
is( $call->run(7),               7, 'use ref setter works too');
is( $ref->get(),                 7 , 'ref setter did works');

$call = Kephra::API::Call::Dynamic->new( $name, 'TestClass', '$ref->set( shift );' );
is( ref $call,               $class, 'created call with ref type but without ref');
is( $call->run(8),            undef, 'can not run call witout ref');
is( $call->is_active(),           1, 'even if it is active');
is( $call->get_reference(),   undef, 'no object ref was stored');
is( $call->set_reference($ref),$ref, 'set object ref');
is( $call->get_reference(),    $ref, 'object ref was now stored');
is( $call->run(8),                8, 'can not run call witout ref');
is( $ref->get(),                  8, 'object setter successful called');

# status
$ref = {1 => 2};
my $status = Kephra::API::Call::Dynamic->new( $name, $ref, $source )->status();
#like( $status,          qr/active/, 'call state has to be in his status report');
#like( $status,         qr/$source/, 'call source has to be in his status report');
#like( $status,           qr/$name/, 'call name has to be in his status report');

# error msg
is( Kephra::API::Call::Dynamic->new(1,2),              undef, 'no call created with missing params');
like( pop(@error),               qr/three to four parameter/, 'error message for not enough params');
is( Kephra::API::Call::Dynamic->new(1,2,3,4,5),        undef, 'no call created with too many params');
like( pop(@error),               qr/three to four parameter/, 'error message for too many params');
is( Kephra::API::Call::Dynamic->new('', $ref, 'txt'),  undef, 'no call created with code without a ref');
like( pop(@error    ),                      qr/does not use/, 'error message for code without "$ref"');
is( Kephra::API::Call::Dynamic->new('', $ref, '$ref->'),undef, 'no call created with bad code');
like( pop(@error),                      qr/not be evaluated/, 'error message for bad code');
is( $call->set_active(),                               undef, 'no state change with no parameter');
like( pop(@error),                   qr/need only a boolean/, 'error message for not enough params on set active');
is( $call->set_reference(),                            undef, 'no reference change with no parameter');
like( pop(@error),                   qr/only a reference of/, 'error message for not enough params on set active');

exit 0;

;

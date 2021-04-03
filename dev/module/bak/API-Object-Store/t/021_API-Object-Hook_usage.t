#!/usr/bin/perl -w
use v5.14;
use warnings;
use Scalar::Util qw(blessed);
use Test::More tests => 87;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API::Object::Hook;
use TestClass;

my (@warning, @error, @note, @report);
my ($class) = ('Kephra::API::Object::Hook');
no strict 'refs';
no warnings 'redefine';
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
use strict;
use warnings;

my ($bid, $aid, $m) = (qw/before after one/);
our $cc = 0;
my $obj = TestClass->new();
is( blessed($obj),        'TestClass', 'created an object');
is( $obj->one(),                    1, 'ran one test method');
is( ($obj->ret(1))[0],              1, 'ran return test method');

is( Kephra::API::Object::Hook::get_methods(),             undef, 'no method has a hook');
is( Kephra::API::Object::Hook::get_before_IDs($obj, $m),      0, 'no hook before method one');
is( Kephra::API::Object::Hook::get_after_IDs($obj, $m),       0, 'no hook after method one');
is( Kephra::API::Object::Hook::get_before($obj, $m, $bid),undef, 'get no hook before method one');
like( pop(@warning) ,                          qr/is installed/, 'particulare hook not there');
is( Kephra::API::Object::Hook::get_before($obj, $m, $aid),undef, 'get no hook after method one');
like( pop(@warning) ,                          qr/is installed/, 'particulare hook not there, right error message');
is( Kephra::API::Object::Hook::get_before_IDs($obj, $m),      0, 'no false hook memory created on before side');
is( Kephra::API::Object::Hook::get_after_IDs($obj, $m),       0, 'no false hook memory created on after side');
is( Kephra::API::Object::Hook::get_methods($obj),             0, 'still no method has a hook');


# create run and delete before hook
my $call = Kephra::API::Object::Hook::add_before($obj, $m, $bid,'$main::cc++');
$cc = 0;
is( ref $call,                             'Kephra::API::Call', 'did create a BEFORE method call hook');
is( ref Kephra::API::Object::Hook::get_before($obj, $m, $bid) , 'Kephra::API::Call', 'get the newly created before hook');
is( Kephra::API::Object::Hook::get_before_IDs($obj, $m),     1, 'one before hook can be listed');
is( (Kephra::API::Object::Hook::get_before_IDs($obj, $m))[0],$bid, 'before hook ID recognized');
is( $cc,                                                     0, 'check var for before hook is still 0');
$obj->one();

is( $cc,                                                     1, 'check var for before hook is after run changed: 1');
Kephra::API::Object::Hook::remove_before($obj, $m, $bid);
is( $cc,                                                     1, 'check var for before hook is again 1');
$obj->one();
is( $cc,                                                     1, 'check var for before hook is after run unchanged: 1');
is( Kephra::API::Object::Hook::get_before($obj, $m, $bid),undef,'deleted hook is gone');
is( Kephra::API::Object::Hook::get_before_IDs($obj, $m),     0, 'no before hook can be listed');
is( Kephra::API::Object::Hook::get_methods($obj),            0, 'no method has a hook again');

# create run and delete after hook
Kephra::API::Object::Hook::add_after($obj, $m, $aid, '$main::cc++');
$cc = 0;
is( ref Kephra::API::Object::Hook::get_after($obj, $m, $aid) ,  'Kephra::API::Call', 'get the newly created after hook');
is( Kephra::API::Object::Hook::get_after_IDs($obj, $m),      1, 'one after hook can be listed');
is( (Kephra::API::Object::Hook::get_after_IDs($obj, $m))[0], $aid, 'after hook ID recognized');
is( $cc,                                                     0, 'check var for after hook is still 0');
$obj->one();
is( $cc,                                                     1, 'check var for after hook is after run changed: 1');
Kephra::API::Object::Hook::remove_after($obj, $m, $aid);
is( $cc,                                                     1, 'check var for after hook is again 1');
$obj->one();
is( $cc,                                                     1, 'check var for after hook is after run unchanged: 1');
is( Kephra::API::Object::Hook::get_after($obj, $m, $aid),undef, 'deleted hook is gone');
is( Kephra::API::Object::Hook::get_after_IDs($obj, $m),      0, 'no after hook can be listed');
is( Kephra::API::Object::Hook::get_methods($obj),            0, 'no method has a hook again');
Kephra::API::Object::Hook::add_after($obj, $m, $aid, $call);
is( (Kephra::API::Object::Hook::get_after_IDs($obj, $m))[0], $aid, 'added hook directly as call');
Kephra::API::Object::Hook::remove_after($obj, $m, $aid);

# hook calls recieving method parameter
$m = 'ret';
$cc = 0;
Kephra::API::Object::Hook::add_before($obj, $m, $bid, '$main::cc++ if $_[1][0] eq 1');
is( $cc,                                                     0, 'check var for before hook is 0');
$obj->ret(1);
is( $cc,                                                     1, 'catched the input data by before hook');
Kephra::API::Object::Hook::remove_before($obj, $m, $bid);
Kephra::API::Object::Hook::add_after($obj, $m, $bid, '$main::cc++ if $_[1][0] eq 1');
$obj->ret(1);
is( $cc,                                                     2, 'catched the input data by after hook');
Kephra::API::Object::Hook::remove_after($obj, $m, $aid);
is( Kephra::API::Object::Hook::get_methods($obj),            1, 'yes deleted wrong hook');
Kephra::API::Object::Hook::remove_after($obj, $m, $bid);
is( Kephra::API::Object::Hook::get_methods($obj),            0, 'no method has a hook again');
is( (Kephra::API::Object::Hook::get_before_IDs($obj, $m)),   0, 'no BEFORE hook ID recognized');
is( (Kephra::API::Object::Hook::get_after_IDs($obj, $m)),    0, 'no AFTER hook ID recognized');

# before and after hooks of same ID communicating
$cc = 0;
Kephra::API::Object::Hook::add_before($obj, $m, $aid, '(1,2)');
Kephra::API::Object::Hook::add_after($obj, $m, $aid, '$main::cc++ if $_[3][0]== 1 and $_[3][1] == 2');
is( (Kephra::API::Object::Hook::get_before_IDs($obj, $m)),   1, 'before hook ID recognized');
is( (Kephra::API::Object::Hook::get_after_IDs($obj, $m)),    1, 'after hook ID recognized');
is( $cc,                                                     0, 'check var is 0 at start');
$obj->ret(1);
is( $cc,                                                     1, 'channeled data from before hook to after hook');

# check bad calls
Kephra::API::Object::Hook::add_before($obj, $m, $aid, '(1,2)');
like( pop(@warning),                     qr/already installed/, 'can not install before hook under same hook ID twice');
Kephra::API::Object::Hook::add_before($obj, $m, $aid, '(1,2)',1);
like( pop(@error),                     qr/need four parameter/, 'add before hook works only with four parameter, not 5');
Kephra::API::Object::Hook::add_before($obj, $m, $aid.$bid);
like( pop(@error),                     qr/need four parameter/, 'add before hook works only with four parameter, not 3');
Kephra::API::Object::Hook::add_before(1, $m, $aid.$bid, '(1,2)');
like( pop(@error),                           qr/not an object/, 'add before hook works only with real objects as first parameter');
Kephra::API::Object::Hook::add_before($obj, $m.$m, $aid.$bid, '(1,2)');
like( pop(@error),                            qr/not a method/, 'add before hook works only with real method as second parameter');
Kephra::API::Object::Hook::add_after($obj, $m, $aid, '(1,2)');
like( pop(@warning),                     qr/already installed/, 'can not install after under same hook ID twice');
Kephra::API::Object::Hook::add_after($obj, $m, $aid, '(1,2)',1);
like( pop(@error),                     qr/need four parameter/, 'add after hook works only with four parameter, not 5');
Kephra::API::Object::Hook::add_after($obj, $m, $aid.$bid);
like( pop(@error),                     qr/need four parameter/, 'add after hook works only with four parameter, not 3');
Kephra::API::Object::Hook::add_after(1, $m, $aid.$bid, '(1,2)');
like( pop(@error),                           qr/not an object/, 'add before hook works only with real objects as first parameter');
Kephra::API::Object::Hook::add_after($obj, $m.$m, $aid.$bid, '(1,2)');
like( pop(@error),                            qr/not a method/, 'add before hook works only with real method as second parameter');

Kephra::API::Object::Hook::remove_before($obj, $m, $aid, 1);
like( pop(@error),                    qr/need three parameter/, 'remove before hook works only with three parameter, not 4');
Kephra::API::Object::Hook::remove_before($obj, $m);
like( pop(@error),                    qr/need three parameter/, 'remove before hook works only with three parameter, not 2');
Kephra::API::Object::Hook::remove_before(1, $m, $aid);
like( pop(@error),                           qr/not an object/, 'remove before hook works only on real objects (first parameter)');
Kephra::API::Object::Hook::remove_before($obj, $m.$m, $aid);
like( pop(@error),                            qr/not a method/, 'remove before hook works only on real methods (second parameter)');
Kephra::API::Object::Hook::remove_before($obj, $m, $bid.$aid);
like( pop(@warning),                         qr/not installed/, 'can not remove before hook with unknon hook ID (third parameter)');
Kephra::API::Object::Hook::remove_after($obj, $m, $aid, 1);
like( pop(@error),                    qr/need three parameter/, 'remove after hook works only with three parameter, not 4');
Kephra::API::Object::Hook::remove_after($obj, $m);
like( pop(@error),                    qr/need three parameter/, 'remove after hook works only with three parameter, not 2');
Kephra::API::Object::Hook::remove_after(1, $m, $aid);
like( pop(@error),                           qr/not an object/, 'remove after hook works only on real objects (first parameter)');
Kephra::API::Object::Hook::remove_after($obj, $m.$m, $aid);
like( pop(@error),                            qr/not a method/, 'remove after hook works only on real methods (second parameter)');
Kephra::API::Object::Hook::remove_after($obj, $m, $bid.$aid);
like( pop(@warning),                         qr/not installed/, 'can not remove after hook with unknown hook ID (third parameter)');

Kephra::API::Object::Hook::get_before($obj, $m, $aid, 1);
like( pop(@error),                    qr/need three parameter/, 'get before hook works only with three parameter, not 4');
Kephra::API::Object::Hook::get_before($obj, $m);
like( pop(@error),                    qr/need three parameter/, 'get before hook works only with three parameter, not 2');
Kephra::API::Object::Hook::get_before(1, $m, $aid);
like( pop(@error),                           qr/not an object/, 'get before hook works only on real objects (first parameter)');
Kephra::API::Object::Hook::get_before($obj, $m.$m, $aid);
like( pop(@error),                            qr/not a method/, 'get before hook works only on real methods (second parameter)');
Kephra::API::Object::Hook::get_before($obj, $m, $bid.$aid);
like( pop(@warning),                               qr/no hook/, 'can not get before hook with unknown hook ID (third parameter)');
Kephra::API::Object::Hook::get_after($obj, $m, $aid, 1);
like( pop(@error),                    qr/need three parameter/, 'get after hook works only with three parameter, not 4');
Kephra::API::Object::Hook::get_after($obj, $m);
like( pop(@error),                    qr/need three parameter/, 'get after hook works only with three parameter, not 2');
Kephra::API::Object::Hook::get_after(1, $m, $aid);
like( pop(@error),                           qr/not an object/, 'get after hook works only on real objects (first parameter)');
Kephra::API::Object::Hook::get_after($obj, $m.$m, $aid);
like( pop(@error),                            qr/not a method/, 'get after hook works only on real methods (second parameter)');
Kephra::API::Object::Hook::get_after($obj, $m, $bid);
like( pop(@warning),                               qr/no hook/, 'can not get after hook with unknown hook ID (third parameter)');

Kephra::API::Object::Hook::get_methods($obj, $m);
like( pop(@error),                           qr/one parameter/, 'list methods with hooks needs one parameter, not two');
Kephra::API::Object::Hook::get_methods();
like( pop(@error),                           qr/one parameter/, 'list methods with hooks needs a parameter');
Kephra::API::Object::Hook::get_methods([]);
like( pop(@error),                           qr/one parameter/, 'list methods with hooks needs object as first parameter');

Kephra::API::Object::Hook::get_before_IDs($obj, $m, 1);
like( pop(@error),                      qr/need two parameter/, 'list before hooks works only with two parameter, not 3');
Kephra::API::Object::Hook::get_before_IDs($obj);
like( pop(@error),                      qr/need two parameter/, 'list before hook works only with two parameter, not 1');
Kephra::API::Object::Hook::get_before_IDs(1, $m);
like( pop(@error),                           qr/not an object/, 'list before hook works only on real objects (first parameter)');
Kephra::API::Object::Hook::get_before_IDs($obj, $m.$m);
like( pop(@error),                            qr/not a method/, 'list before hook works only on real methods (second parameter)');
Kephra::API::Object::Hook::get_before_IDs($obj, $m, 1);
like( pop(@error),                      qr/need two parameter/, 'list after hook works only with two parameter, not 3');
Kephra::API::Object::Hook::get_after_IDs($obj);
like( pop(@error),                      qr/need two parameter/, 'list after hook works only with two parameter, not 1');
Kephra::API::Object::Hook::get_after_IDs(1, $m);
like( pop(@error),                           qr/not an object/, 'list after hook works only on real objects (first parameter)');
Kephra::API::Object::Hook::get_after_IDs($obj, $m.$m);
like( pop(@error),                            qr/not a method/, 'list after hook works only on real methods (second parameter)');

exit 0;

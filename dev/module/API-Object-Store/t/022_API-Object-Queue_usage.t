#!/usr/bin/perl -w
use v5.14;
use warnings;
use Scalar::Util qw(blessed);
use Test::More tests => 139;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API::Object::Queue;
use TestClass;

my (@warning, @error, @note, @report);
my ($class, $item_class, @item) = ('Kephra::API::Object::Queue', 'TestClass');
no strict 'refs';
no warnings 'redefine';
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
use strict;
use warnings;

my $q = Kephra::API::Object::Queue->new();
my $a = [];
my @c;
push @c, TestClass->new() for 1..5;

# good init state
is( blessed($q),                                $class, 'created a queue object');
is( $q->item_class(),                               '', 'no input filter is on');
is( $q->item_count(),                                0, 'no items yet there');
is( $q->item_position(5),                           -1, 'no specific item there, so no identifiable position');
is( $q->append_item(''),                             1, 'accpeting text when no class filter is in effect');
is( $q->item_count(),                                1, 'after that one item is in the queue');
is( $q->item_position(''),                           0, 'text is in first position in queue');
is( $q->append_item($a),                             1, 'accpeting refs when no class filter is in effect');
is( $q->item_count(),                                2, 'after that two item are in the queue');
is( $q->item_position(''),                           0, 'text is still in first position in queue');
is( $q->item_position($a),                           1, 'array  ref is now in second position in queue');
is( $q->prepend_item($q),                            1, 'accpeting any class when no class filter is in effect');
is( $q->item_count(),                                3, 'after that three item are in the queue');
is( $q->item_position($q),                           0, 'queue object ref got right position');
is( $q->item_position(''),                           1, 'text got right position in queue');
is( $q->item_position($a),                           2, 'array ref got right position');
is( $q->get_item(0),                                $q, 'first item in queue is the queue itself');
is( $q->get_item(1),                                '', 'second item is the empty text');
is( $q->get_item(2),                                $a, 'third comes the array');

# basic add remove items (with and without input filter)
$q = Kephra::API::Object::Queue->new('TestClass');
is( $q->item_class(),                      'TestClass', 'tells correctly what object queue accepts');
is( $q->append_item(''),                         undef, 'when input filter is on, none refs don\'t get in');
is( $q->item_count(),                                0, 'after that the queue is still empty');
like( pop(@error),                     qr/not derived/, 'right error message for rejecting string input');
is( $q->append_item([]),                         undef, 'when input filter is on, none objects don\'t get in');
is( $q->item_count(),                                0, 'after that the queue is still empty');
like( pop(@error),                     qr/not derived/, 'right error message for rejecting array input');
is( $q->prepend_item($q),                        undef, 'when input filter is on, objects of other classes has to stay out either');
is( $q->item_count(),                                0, 'after that the queue is still empty');
like( pop(@error),                     qr/not derived/, 'right error message for rejecting wrong object input');
is( $q->append_item($c[0]),                          1, 'when input filter is on, objects defined classes go in back');
is( $q->item_count(),                                1, 'now queue has an item');
is( $q->item_position($c[0]),                        0, 'it is on position zero'); 
is( $q->prepend_item($c[0]),                         1, 'when input filter is on, objects defined classes go in front');
is( $q->item_count(),                                2, 'now queue has two item');  # the don't have to be unique
is( $q->remove_item($c[0]),                          2, 'removed same object twice'); 
is( $q->item_count(),                                0, 'queue is empty again after removing all items');

# unique
$q->append_item($c[0]);
is( $q->append_item($c[0], 'unique'),                1, 'can not append item twice when demanding it should be unique');
is( $q->item_count(),                                1, 'queue got not longer because item was not unique');
is( $q->prepend_item($c[0], 'unique'),               1, 'can not prepend item twice when demanding it should be unique');
is( $q->item_count(),                                1, 'queue got still not longer becasue item was again not unique');
$q->remove_item($c[0]);

# get and set queue properties
is( $q->is_front_closed(),                           0, 'per default queue front are open');
is( $q->close_front(1),                              1, 'set queue front to closed');
is( $q->is_front_closed(),                           1, 'queue front is now closed');
is( $q->close_front(0),                              0, 'set queue front to open again');
is( $q->is_front_closed(),                           0, 'and queue front is open');

is( $q->is_back_closed(),                            0, 'per default back front are open');
is( $q->close_back(1),                               1, 'set queue back to closed');
is( $q->is_back_closed(),                            1, 'queue back is now closed');
is( $q->close_back(0),                               0, 'set queue back to open again');
is( $q->is_back_closed(),                            0, 'and queue back is open');

is( $q->get_min_quota(),                             0, 'per default there is no minimum quota');
is( $q->set_min_quota(2),                            2, 'set minimum quota to 2');
is( $q->get_min_quota(),                             2, 'minimum quota is now 2');

is( $q->get_max_quota(),                             0, 'per default there is no maximum quota');
is( $q->set_max_quota(5),                            5, 'set maximum quota to 5');
is( $q->get_max_quota(),                             5, 'maximum quota is now 5');

is( $q->set_min_quota(7),                        undef, 'can not set minimum quota larger than maximum');
like( pop(@warning),               qr/bigger than max/, 'right error message for for too large min quota');
is( $q->get_min_quota(),                             2, 'minimum quota is still 2');
is( $q->set_max_quota(1),                        undef, 'can not set maximum quota smaller than minimum');
like( pop(@warning),              qr/smaller than min/, 'right error message for too small max quota');
is( $q->get_max_quota(),                             5, 'maximum quota is still 5');

# set by constructor
my $qq = Kephra::API::Object::Queue->new('TestClass','closed','closed',12,5);
is( $qq->item_class(),                     'TestClass', 'tells correctly what objects this queue accepts');
is( $qq->is_front_closed(),                          1, 'queue front state was set by constructor to closed');
is( $qq->is_back_closed(),                           1, 'queue back state was set by constructor to closed');
is( $qq->get_max_quota(),                           12, 'maximum quota was set by constructor to 12');
is( $qq->get_min_quota(),                            5, 'minimum quota was set by constructor to 5');

# add remove items when closed or limited size
is( $q->item_count(),                                0, 'starting with empty queue');
$q->close_front(1);
is( $q->prepend_item($c[0]),                     undef, 'can not prepend to closed queue');
like( pop(@note),                     qr/closed queue/, 'rejection of the prepend was noted');
$q->close_back(1);
is( $q->append_item($c[0]),                      undef, 'can not append to closed queue');
like( pop(@note),                     qr/closed queue/, 'rejection of the append was noted');
$q->close_front(0);
$q->close_back(0);
is( $q->get_max_quota(),                             5, 'maximum quota is still on 5');
$q->append_item($c[0]) for 1 .. 7;
is( $q->item_count(),                                5, 'maximum quota worked');
is( scalar(@item = $q->set_max_quota(4)),            1, 'decrease max quota popped out one element from q');
is( $q->get_max_quota(),                             4, 'queue content adapted to new quota');

$q->set_max_quota(5);
$q->set_min_quota(2);
is( scalar (@item = $q->remove_front(10)),           2, 'was allowed to remove three items there - min');
$q->append_item($c[0]) for 1 .. 5;                     # up to 5 items again
is( $q->remove_front(10, 'allornothing'),        undef, 'was not allowed to remove any items becasue too much or nothing policy');
$q->set_min_quota(0);
is( $q->remove_front(10, 'allornothing'),        undef, 'again no items removed on all or nothing policy, even when there is no minimal quota');
is( scalar(@item = $q->remove_front(2)),             2, 'got as much items as demanded because it was under limit');
$q->append_item($c[0]) for 1 .. 5;                     # up to 5 items again
$q->set_min_quota(2);
is( scalar(@item = $q->remove_front()),              3, 'max - min = 3 items could be removed');
$q->append_item($c[0]) for 1 .. 5;                     # up to 5 items again
$q->set_min_quota(0);
is( scalar(@item = $q->remove_front()),              5, 'max - min = 5 items could be removed');

# status
my $status = $q->status();
like( $status,          qr/Kephra::API::Object::Queue/, 'status has to contain $self reference');
like( $status,                          qr/front is 0/, 'right front status');
like( $status,                           qr/back is 0/, 'right back status');
like( $status,                            qr/min => 0/, 'right minimum quota');
like( $status,                            qr/max => 5/, 'right maximum quota');
like( $status,                          qr/0 elements/, 'right amount of content');
like( $status,                      qr/type TestClass/, 'right content type');

# check error messages
Kephra::API::Object::Queue->new('Class', 'closed', 'closed', 12, 5, 1);
like( pop(@error),    qr/only five optional parameter/,  'new takes only 5 parames');
is( blessed(Kephra::API::Object::Queue->new()),          'Kephra::API::Object::Queue', 'created a queue object with no parameter');
is( blessed(Kephra::API::Object::Queue->new('a')),       'Kephra::API::Object::Queue', 'created a queue object with one parameter');
is( blessed(Kephra::API::Object::Queue->new('a','open')),'Kephra::API::Object::Queue', 'created a queue object with two parameter');
is( blessed(Kephra::API::Object::Queue->new('a','open','open')), 'Kephra::API::Object::Queue', 'created a queue object with three parameter');
is( blessed(Kephra::API::Object::Queue->new('a','open','open',10)),'Kephra::API::Object::Queue', 'created a queue object with four parameter');
is( blessed(Kephra::API::Object::Queue->new('a','open','open',10,5)),'Kephra::API::Object::Queue', 'created a queue object with five parameter');

$q->is_front_closed(1);
like( pop(@error),                    qr/no parameter/, 'get_front_state takes no params');
$q->is_back_closed(1);
like( pop(@error),                    qr/no parameter/, 'get_back_state takes no params');
$q->close_front(1,2);
like( pop(@error),                   qr/one parameter/, 'set_front_state takes one params');
$q->close_back(1,2);
like( pop(@error),                   qr/one parameter/, 'set_back_state takes one params');

$q->get_min_quota(1);
like( pop(@error),                    qr/no parameter/, 'get_min_quota takes no params');
$q->get_max_quota(1);
like( pop(@error),                    qr/no parameter/, 'get_max_quota takes no params');
$q->set_min_quota (1,2);
like( pop(@error),                   qr/one parameter/, 'set_min_quota takes one params');
$q->set_min_quota ('bub');
like( pop(@error),                   qr/one parameter/, 'set_min_quota takes no text input');
$q->set_min_quota (0.25);
like( pop(@error),                   qr/one parameter/, 'set_min_quota takes no rational input');
$q->set_min_quota (-5);
like( pop(@error),                   qr/one parameter/, 'set_min_quota takes no negative input');
$q->set_max_quota (1,2);
like( pop(@error),                   qr/one parameter/, 'set_max_quota takes one params');
$q->set_max_quota ('destiny');
like( pop(@error),                   qr/one parameter/, 'set_max_quota takes not text input');
$q->set_max_quota (2.3);
like( pop(@error),                   qr/one parameter/, 'set_max_quota takes no rational number as input');
$q->set_max_quota (-3);
like( pop(@error),                   qr/one parameter/, 'set_max_quota takes no negative input');

$q->item_class(1);
like( pop(@error),                    qr/no parameter/, 'get_item_class takes no params');
$q->item_count(1);
like( pop(@error),                    qr/no parameter/, 'item_count takes no params');
$q->get_item();
like( pop(@error),                   qr/one parameter/, 'get_item takes one params, not none');
$q->get_item(1,3);
like( pop(@error),                   qr/one parameter/, 'get_item takes one params, not two');
$q->get_item(1.3);
like( pop(@error),                   qr/one parameter/, 'get_item takes nor real number input');
$q->get_item('gut');
like( pop(@error),                   qr/one parameter/, 'get_item takes nor real string input');
$q->item_position();
like( pop(@error),                   qr/one parameter/, 'item_position takes one params, not none');
$q->item_position(1,2);
like( pop(@error),                   qr/one parameter/, 'item_position takes one params, not two');

is( $q->prepend_item(),                          undef, 'prepend_item takes one or two params, not zero');
like( pop(@error),            qr/one or two parameter/, 'prepend_item complained about getting zero params');
is( $q->prepend_item(1,2,3),                     undef, 'prepend_item takes one or two params, not three');
like( pop(@error),            qr/one or two parameter/, 'prepend_item complained about getting three params');
is( $q->append_item(),                           undef, 'append_item takes one or two params, not zero');
like( pop(@error),            qr/one or two parameter/, 'append_item complained about getting zero params');
is( $q->append_item(1,2,3),                      undef, 'append_item takes one or two params, not three');
like( pop(@error),            qr/one or two parameter/, 'append_item complained about getting three params');
is( $q->remove_front(1,2,3),                     undef, 'remove_front takes up to two params, not three');
like( pop(@error),          qr/two optional parameter/, 'remove_front complains about getting three params');
is( $q->remove_front('-', 1),                    undef, 'remove_front doesn\'t take text as first param');
like( pop(@error),                 qr/positive number/, 'remove_front complains about text input');
is( $q->remove_front(1.2, 1),                    undef, 'remove_front doesn\'t take real number as first param');
like( pop(@error),                 qr/positive number/, 'remove_front complains about real input');
is( $q->remove_front(-1, 1),                     undef, 'remove_front doesn\'t take neagtive number as first param');
like( pop(@error),                 qr/positive number/, 'remove_front complains about neagtive input');

is( $q->remove_item(),                           undef, 'remove_item takes one params, not none');
like( pop(@error),                   qr/one parameter/, 'remove_item complains about getting no input');
is( $q->remove_item(1,2),                        undef, 'remove_item takes one params, not two');
like( pop(@error),                   qr/one parameter/, 'remove_item complains about getting too much input');

$q->status(1);
like( pop(@error),                    qr/no parameter/, 'status takes no params');


exit 0;

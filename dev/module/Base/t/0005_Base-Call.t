#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 48;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Call qw/new_call/;

is (ref Kephra::Base::Call->new(), '', 'new needs at least one argument');
my $call = Kephra::Base::Call->new(1);
is (ref $call, 'Kephra::Base::Call', 'created most simple call');
is ($call->run(), 1,                 'call object can run evaluated code');
is ($call->get_source(), 1,          'call objects shows sources');

my $clone = $call->new();
is (ref $call, 'Kephra::Base::Call', 'recreated most simple call');
is ($call->run(), 1,                 'sibling works');
is ($call->get_source(), 1,          'sibling shows sources');
$clone = $call->clone();
is (ref $call, 'Kephra::Base::Call', 'cloned most simple call');
is ($call->run(), 1,                 'clone works');
is ($call->get_source(), 1,          'clone shows sources');
$call = new_call('1');
is (ref $call, 'Kephra::Base::Call', 'sub new_call could be imported');

$call = Kephra::Base::Call->new('$_[0]');
is ($call->run(2), 2,                'args get transported');
is ($call->run('eq'), 'eq',          'every time');

my $counter = Kephra::Base::Call->new('state $cc = 0; $cc++;');
is ($counter->run(), 0,              'counter works');
is ($counter->run(), 1,              'every time');

$counter = $counter->new('++$state;', 2);
is (ref $counter, 'Kephra::Base::Call', 'created counter by calling new on object');
is ($counter->get_state(), 2,        'got init data back');
is ($counter->run(), 3,              'data counter works');
is ($counter->run(), 4,              'every time');
is ($counter->get_state(), 4,        'got current data back');
$counter->set_state(8);
is ($counter->get_state(), 8,        'set data works');
is ($counter->run(), 9,              'call works now with set data');

my $siblingcc = $counter->clone(5); # create couter from 5 on
is (ref $siblingcc, 'Kephra::Base::Call', 'recreated counter by clone');
ok (int $counter != int $siblingcc,  'clone created fresh object');
is ($siblingcc->get_state(), 5,      'counter sibling got his init data');
is ($siblingcc->run(), 6,            'counter sibling works');
is ($counter->get_state(), 9,        'original counter kept unchanged by running the clone');
$clone = $siblingcc->clone();
is ($clone->get_state(), 6,          'counter clone took data from origin');
is ($clone->run(), 7,                'counter clone works');
is ($counter->get_state(), 9,        'original counter kept untouched');

$counter = new_call('++$state;', 3);
is ($counter->run(), 4,              'also counter created by shortcut works');
$counter = new_call('++$state;', 's', 'int');
is (ref $counter, '',                'bad init value returns error');

$counter = new_call('++$state;', 6, 'int');
is (ref $counter, 'Kephra::Base::Call', 'created call with set type');
is ($counter->get_state(), 6,           'typed call stored its init value');
is ($counter->run(), 7,                 'typed call runs its code');
is ($counter->set_state(9), 9,          'set state of typed call');
is ($counter->get_state(), 9,           'state of typed call was stored');
is ($counter->set_state(9.1), 9,        'reject malformed data while set state of typed call');
is ($counter->get_state(), 9,           'old state of typed call still there');

$counter = new_call('++$state;',  -4, 'int', 'int_pos');
is (ref $counter, 'Kephra::Base::Call', 'created call with get and set type');
ok ($counter->get_state() ne '-4',      'can not get init value due get type');
is ($counter->set_state(-1), -1,        'set state of double typed call to calue I can set but not get');
ok ($counter->get_state() ne '-1',      'could not get the value');
is ($counter->run(), 0,                 'double typed call runs its code');
is ($counter->get_state(), 0,           'state of double typed call was stored');
is ($counter->set_state(9), 9,          'set state of double typed call');
is ($counter->set_state(9.1), 9,        'reject malformed data while set state of typed call');
is ($counter->get_state(), 9,           'old state of typed call still there');

exit 0;


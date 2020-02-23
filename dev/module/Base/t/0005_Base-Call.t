#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 26;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Call qw/new_call/;

my $call = Kephra::Base::Call->new(1);
is (ref $call, 'Kephra::Base::Call', 'created most simple call');
is ($call->run(), 1,                 'call works');
is ($call->get_source(), 1,          'call shows sources');
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

$counter = Kephra::Base::Call->new('++$state;', 2);
is ($counter->get_state(), 2,        'got init data back');
is ($counter->run(), 3,              'data counter works');
is ($counter->run(), 4,              'every time');
is ($counter->get_state(), 4,        'got current data back');
$counter->set_state(8);
is ($counter->get_state(), 8,        'set data works');
is ($counter->run(), 9,              'call works now with set data');

my $siblingcc = $counter->new(5); # create couter from 5 on
is (ref $siblingcc, 'Kephra::Base::Call', 'recreated counter');
is ($siblingcc->get_state(), 5,      'counter sibling got his init data');
is ($siblingcc->run(), 6,            'counter sibling works');
$clone = $siblingcc->clone();
is ($clone->get_state(), 6,          'counter clone took data from origin');
is ($clone->run(), 7,                'counter clone works');

$counter = new_call('++$state;', 3);
is ($counter->run(), 4,              'also counter created by shortcut works');

exit 0;


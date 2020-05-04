#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 133;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Call qw/new_call/;
use Kephra::Base::Data::Type::Standard qw/check_type/;

my $class = 'Kephra::Base::Call';
my $tclass = 'Kephra::Base::Data::Type::Simple';
sub simple_type { Kephra::Base::Data::Type::Simple->new(@_) }
my $Tval  = simple_type('value', 'not a reference', 'not ref $value', undef, '');
my $Tint  = simple_type('int', 'integer number', 'int $value eq $value', $Tval, 0);
my $Aref  = [];
my ($call, $clone, $counter, $state, $copy);

is (ref Kephra::Base::Call->new(),  '', 'new needs at least one positional argument');
is (ref Kephra::Base::Call->new({}),'', 'new needs at least one named argument');
is (ref Kephra::Base::Call->new('blub'), '', 'need valid perl code to make a Call object');
$call = Kephra::Base::Call->new(1);
is (ref $call, $class,                  '- created most simple KB::Call object with positional argument');
is ($call->run(), 1,                    'method run works');
is ($call->get_code(), 1,               'code getter works');
is ($call->get_type(), undef,           'type getter works');
is ($call->get_state(), undef,          'state getter works');
is ($call->set_state(3), 3,             'state setter works');
is ($call->get_state(), 3,              'state getter works');

$call = Kephra::Base::Call->new({code =>1});
is (ref $call, $class,                  '- created most simple KB::Call object with named argument');
is ($call->run(), 1,                    'method run works');
is ($call->get_code(), 1,               'code getter works');
is ($call->get_type(), undef,           'type getter works');
is ($call->get_state(), undef,          'state getter works');

$clone = $call->clone();
is (ref $clone, $class,                 '- created clone of most simple KB::Call object');
is ($clone->run(), 1,                   'method run works');
is ($clone->get_code(), 1,              'code getter works');
is ($clone->get_type(), undef,          'type getter works');
is ($clone->get_state(), undef,         'state getter works');

$copy = Kephra::Base::Call->restate($call->state);
is (ref $clone, $class,                 '- created copy of most simple KB::Call object');
is ($clone->run(), 1,                   'method run works');
is ($clone->get_code(), 1,              'code getter works');
is ($clone->get_type(), undef,          'type getter works');
is ($clone->get_state(), undef,         'state getter works');


$call = Kephra::Base::Call->new('$_[0]');
is ($call->run(2), 2,                   'args to code get transported');
is ($call->run('eq'), 'eq',             'every time');
is (int $call->run($Aref), int $Aref,   'even on refs');

$counter = Kephra::Base::Call->new('state $cc = 0; $cc++;');
is (ref $call, $class,                  '- created call with none state variables');
is ($counter->run(), 0,                 'counter initialized with none state var');
is ($counter->run(), 1,                 'counter works with none state var');

$counter = Kephra::Base::Call->new('$state++');
is (ref $call, $class,                  '- created call using the official state variable');
is ($counter->run(), 0,                 'counter initialized with state var');
is ($counter->run(), 1,                 'counter works with state var');

$counter = Kephra::Base::Call->new('$state++', 7);
is ($counter->get_state(),      7,      'got state from argument of new');
is ($counter->run(),            7,      'code uses state value given as argument');
is ($counter->run(),            8,      'counter works');
is ($counter->set_state(5),     5,      'set state by setter');
is ($counter->get_state(),      5,      'state getter still works');
is ($counter->run(),            5,      'value set by setter is arrived in code');
is ($counter->run(),            6,      'counter works');
is ($counter->get_type(),   undef,      'no type was set');
is ($counter->set_state(8.8), 8.8,      'setter accepts bad value');
is ($counter->run(),          8.8,      'counter restarts with 0 after bad value');
is ($counter->run(),          9.8,      'counter works even with real numbers');


$counter = new_call({code => '$state++', state => 8, type => 'int'});
is (ref $counter, $class,               '- created KB::Call with shortcut sub and standard type name');
my $type = $counter->get_type();
is (ref $type,  $tclass,                'standard type name got resolved');
is ($counter->get_type->get_name, 'int','looks like got resolved to right type');
is ($counter->get_code(), '$state++',   'getter gives correct source code');
is ($counter->get_state(),  8,          'getter still works');
is ($counter->set_state(1), 1,          'set state by setter with valid int');
is ($counter->get_state(),  1,          'new value was set');
isnt ($counter->set_state('+'), '+',    'state setter returned error because type mismatch of input');
is ($counter->get_state(),  1,          'previous state still present');


$counter = Kephra::Base::Call->new('$state++', 9, 'int');
is (ref $counter, $class,               '- created KB::Call with type restriction of state by standard type');
$type = $counter->get_type();
is (ref $type,  $tclass,                'standard type name got resolved');
is ($type->get_name, 'int',             'looks like got resolved to right type');
is ($counter->get_code(), '$state++',   'getter gives correct source code');
is ($counter->get_state(),  9,          'getter still works');
is ($counter->set_state(2), 2,          'set state by setter with valid int');
is ($counter->get_state(),  2,          'new value was set');
isnt ($counter->set_state('-'), '-',    'state setter returned error because type mismatch of input');
is ($counter->get_state(),  2,          'previous state still present');

$clone = $counter->clone();
is (ref $clone, $class,                 '- created KB::Call clone');
isnt($clone, $counter,                  'clone is different ref from original');
is ($clone->get_type->get_name, 'int',  'looks like clone got right standard type');
is ($clone->get_code(),  '$state++',    'getter gives correct source code');
is ($clone->get_state(),  2,            'getter gives correct state value');
is ($clone->set_state(3), 3,            'set state by setter with valid int');
is ($clone->get_state(),  3,            'new value was set');
isnt ($clone->set_state(2.2), 2.2,      'state setter returned error because type mismatch of input');
is ($clone->get_state(),  3,            'previous state still present');
is ($clone->run(),        3,            'clone code does run');
is ($clone->run(),        4,            'clone code works');

$state = $clone->state();
is (ref $state, 'HASH',                 'saved state of Call copy into HASH ref');
is ($state->{'std_type'}, 'int',        'only type name is saved from standard type');
$copy = Kephra::Base::Call->restate($state);
is (ref $copy, $class,                  '- created KB::Call copy of a clone');
isnt($copy, $counter,                   'copy ref is different ref from original');
isnt($copy, $clone,                     'copy ref is different ref from clone');
is ($copy->get_type->get_name, 'int',   'looks like copy got right standard type');
is ($copy->get_code(),  '$state++',     'getter gives correct source code');
is ($copy->get_state(),  5,             'getter gives correct state value');
is ($copy->set_state(4), 4,             'set state by setter with valid int');
is ($copy->get_state(),  4,             'new value was set');
isnt ($copy->set_state('#'), '#',       'state setter returned error because type mismatch of input');
is ($copy->get_state(),  4,             'previous state still present');
is ($copy->run(),        4,             'clone code does run');
is ($copy->run(),        5,             'clone code works');

$clone = $copy->clone();
is (ref $clone, $class,                 '- created KB::Call copy of clone of copy');
isnt($clone, $copy,                     'clone is different ref from "copy" (original)');
is ($clone->get_type->get_name, 'int',  'looks like clone got right standard type');
is ($clone->get_code(),  '$state++',    'getter gives correct source code');
is ($clone->get_state(),  6,            'getter gives correct state value');
is ($clone->set_state(5), 5,            'set state by setter with valid int');
is ($clone->get_state(),  5,            'new value was set');
isnt ($clone->set_state(1.2), 1.2,      'state setter returned error because type mismatch of input');
is ($clone->get_state(),  5,            'previous state still present');
is ($clone->run(),        5,            'clone code does run');
is ($clone->run(),        6,            'clone code works');


$counter = Kephra::Base::Call->new({code => '$state++', state => 12, type => $Tint});
is (ref $counter, $class,               '- created KB::Call with type restriction  and HASH args');
is (int $Tint, int $counter->get_type(),'type object was stored properly');
is ($counter->get_code(), '$state++',   'getter gives correct source code');
is ($counter->get_state(), 12,          'getter still works');
is ($counter->set_state(6), 6,          'set state by setter with valid int');
is ($counter->get_state(),  6,          'new value was set');
isnt ($counter->set_state('-'), '-',    'state setter returned error because type mismatch of input');
is ($counter->get_state(),  6,          'previous state still present');

$state = $counter->state();
is (ref $state, 'HASH',                 'saved state of Call into HASH ref');
is (ref $state->{'type'}, 'HASH',       'none standard type state was saved in HASH');
$copy = Kephra::Base::Call->restate($state);
is (ref $copy, $class,                  '- created copy of a KB::Call');
isnt($copy, $counter,                   'copy ref is different ref from original');
isnt (int $Tint, int $copy->get_type(), 'type object got marshalled too');
is ($copy->get_code(),  '$state++',     'getter gives correct source code');
is ($copy->get_state(),  6,             'getter gives correct state value');
is ($copy->set_state(7), 7,             'set state by setter with valid int');
is ($copy->get_state(),  7,             'new value was set');
isnt ($copy->set_state('.'), '.',       'state setter returned error because type mismatch of input');
is ($copy->get_state(),  7,             'previous state still present');
is ($copy->run(),        7,             'code of copy does run');
is ($copy->run(),        8,             'code of copy works');

$clone = $copy->clone();
is (ref $clone, $class,                 '- created KB::Call clone of copy');
isnt($clone, $copy,                     'clone is different ref from "copy"');
isnt($clone, $counter,                  'clone is different ref from "original"');
is ($clone->get_type->get_name, 'int',  'looks like clone got right standard type');
is (int $clone->get_type, int $copy->get_type(), 'type object reference got copied');
is ($clone->get_code(),  '$state++',    'getter gives correct source code');
is ($clone->get_state(),  9,            'getter gives correct state value');
is ($clone->set_state(8), 8,            'set state by setter with valid int');
is ($clone->get_state(),  8,            'new value was set');
isnt ($clone->set_state(1.2), 1.2,      'state setter returned error because type mismatch of input');
is ($clone->get_state(),  8,            'previous state still present');
is ($clone->run(),        8,            'clone code does run');
is ($clone->run(),        9,            'clone code works');

exit 0;

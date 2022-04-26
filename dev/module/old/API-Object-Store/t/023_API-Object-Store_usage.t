#!/usr/bin/perl -w
use v5.14;
use warnings;
use Scalar::Util qw(blessed);
use Test::More tests => 162;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API::Object::Store;
use TestClass;
use DerivedTestClass;

my (@warning, @error, @note, @report);
my ($class, $item_class, $ID, $item, @a) = ('Kephra::API::Object::Store', 'TestClass');
no strict 'refs';
no warnings 'redefine';
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
*{'Kephra::API::Call::error'}   = sub { undef; };
*{'Kephra::API::Call::warning'} = sub { undef; };
*{'Kephra::API::Call::note'}    = sub { undef; };
*{'Kephra::API::Call::report'}  = sub { undef; };
*{'Kephra::API::Call::Dynamic::error'}   = sub { undef; };
*{'Kephra::API::Call::Dynamic::warning'} = sub { undef; };
*{'Kephra::API::Call::Dynamic::note'}    = sub { undef; };
*{'Kephra::API::Call::Dynamic::report'}  = sub { undef; };
*{'Kephra::API::Call::Template::error'}   = sub { undef; };
*{'Kephra::API::Call::Template::warning'} = sub { undef; };
*{'Kephra::API::Call::Template::note'}    = sub { undef; };
*{'Kephra::API::Call::Template::report'}  = sub { undef; };
*{'Kephra::API::Call::Dynamic::Template::error'}   = sub { undef; };
*{'Kephra::API::Call::Dynamic::Template::warning'} = sub { undef; };
*{'Kephra::API::Call::Dynamic::Template::note'}    = sub { undef; };
*{'Kephra::API::Call::Dynamic::Template::report'}  = sub { undef; };
use strict;
use warnings;

my $store = Kephra::API::Object::Store->new($item_class, {}, 0);
my @tc; push @tc, TestClass->new($_) for 0..4;

# init state and simple add get remove items
is( blessed($store),                            $class, 'created a store object');
is( $store->item_class(),                  $item_class, 'get correct class of all items stored here');
is( $store->get_item_IDs(),                      undef, 'no items yet there');
is( $store->get_item_by_ID('randomID'),          undef, 'no specific item there');
is( $store->remove_item('randomID'),             undef, 'can\'t delete anything');
is( $ID = $store->add_item($tc[0]),                  0, 'could add an item');
is( $store->add_item($tc[1]),                        1, 'could add another item');
is( scalar (@a=$store->get_item_IDs()),              2, 'have two items stored now');
is( ($store->get_item_IDs())[0],                     0, 'listing first ID');
is( ($store->get_item_IDs())[1],                     1, 'listing second ID');
is( $store->get_item_by_ID(0),                  $tc[0], 'got first item by ID');
is( $store->get_item_by_ID(1),                  $tc[1], 'got second item by ID');
is( $store->get_ID_by_item($tc[0]),                  0, 'got ID of first item');
is( $store->get_ID_by_item($tc[1]),                  1, 'got ID of second item');
my @ret = $store->delegate_method('ret', 5);
is( scalar @ret,                                     2, 'got right amount return values from delegated method calls');
is( $ret[0],                                         5, 'got right return value from first delegated method call');
is( $ret[1],                                         5, 'got right return value from second delegated method call');
is( scalar $store->delegate_method('ret', 5, 1),     4, 'got right amount return values from delegated method calls with two parameter');
is( $store->remove_item(0),                     $tc[0], 'delete first item');
is( $store->get_item_by_ID(0),                   undef, 'item number one is no longer there');
is( $store->get_item_by_ID(1),                  $tc[1], 'item number still is there');
is( scalar (@a=$store->get_item_IDs()),              1, 'have one items stored now');
is( ($store->get_item_IDs())[0],                     1, 'remained the right item');
is( $store->remove_item($tc[1]),                $tc[1], 'delete second item directly');
is( $store->get_item_IDs(),                      undef, 'no items to list again');
is( $store->add_item(DerivedTestClass->new()),       2, 'could add object rom derived class');
is( ref $store->remove_item(2),     'DerivedTestClass', 'removed derived class object');

# use hooks
is( scalar(@a=$store->item_attributes()),                 0, 'this store knows about no item attributes');
my $hookstore = Kephra::API::Object::Store->new($item_class, {get => 'set', init => ''}, 0);
is( blessed($hookstore),                             $class, 'created a store object with hooks');
is( scalar(@a=$hookstore->item_attributes()),         2, 'this store knows about two item attributes');
is( (@a=$hookstore->item_attributes())[0],        'get', 'first observed item attribute is get');
is( (@a=$hookstore->item_attributes())[1],       'init', 'second observed item attribute is init');

$hookstore->add_item($tc[$_]) for 0..4;
is(scalar(@a=$hookstore->get_attribute_values('init')),     5, 'only one distinct value in attribute "init" (of all stored objects)');
is(scalar(@a=$hookstore->get_item_by_atttibute('init', 0)), 1, 'get one item by attribute "init" value');
is(($hookstore->get_item_by_atttibute('init', 0))[0],  $tc[0], 'get right item by attribute "init" value');
is(scalar(@a=$hookstore->get_item_by_atttibute('init', 2)), 1, 'get one item by another attribute "init" value');
is(($hookstore->get_item_by_atttibute('init', 2))[0],  $tc[2], 'get right item by another attribute "init" value');

is( $hookstore->get_attribute_values('get'),       1, 'all getter/setter values are initially set to same value');
is(scalar(@a=$hookstore->get_item_by_atttibute('get','val')),5, 'get five items that have the "get" attribute on value "val"');
$tc[$_]->set($_+ 5) for 0..4;
is( $hookstore->get_item_by_atttibute('get','val'),0, 'no test objects left with initial value');
is( $hookstore->get_attribute_values('get'),       5, 'five distinct values in attribute "get" (of all stored objects)');
is( ($hookstore->get_item_by_atttibute('get', 5))[0],   $tc[0], 'get right item by attribute "GET" value 5');
is( ($hookstore->get_item_by_atttibute('get', 7))[0],   $tc[2], 'get right item by attribute "GET" value 7');
$hookstore->remove_item($_) for 0..4;
is( $hookstore->get_attribute_values('get'),       0, 'after items are deleted you can not find them by attribute');

# history
is( $hookstore->has_history(),                     0, 'this store has no history');
is( $hookstore->get_latest_item(),             undef, 'so it can deliver no items from history');
my $histore = Kephra::API::Object::Store->new($item_class, {}, 3);
is( blessed($histore),                        $class, 'created a store object with history');
is( $histore->has_history(),                       1, 'this store has a history');
$histore->add_item($tc[$_]) for 0..4;
is( $histore->get_latest_item(),                   0, 'no items in history yet');
is( $histore->get_latest_item(1),                  0, 'if history is empty now items on abck seats either');
is( $histore->use_item(0),                         1, 'was allowed to mark as used because it is in store');
is( $histore->get_latest_item(),              $tc[0], 'got latest item');
is( $histore->get_latest_item(0),             $tc[0], 'got latest item explicitly');
is( $histore->get_latest_item(1),                  0, 'history has length 1 yet so no second item');
is( $histore->use_item(3),                         1, 'was allowed to mark as used because it is in store');
is( $histore->get_latest_item(),              $tc[3], 'got new latest item');
is( $histore->get_latest_item(1),             $tc[0], 'former first is now second');
$histore->remove_item(3);
is( $histore->get_latest_item(0),             $tc[0], 'latest item was deleted so second is first again');
is( $histore->use_item(3),                     undef, 'deleted item can not be used');
is( $histore->use_item($tc[1]),                    1, 'used item directly');
is( $histore->get_latest_item(),              $tc[1], 'got newest latest item');
is( $histore->get_latest_item(1),             $tc[0], 'former first is now second again');
$histore->remove_item($_) for 0,1;
is( $hookstore->get_latest_item(),             undef, 'history is empty again after all items are gone');

# factory - default constructor call that uses: class->new
($item, $ID)  = $store->new_item([7]);
is( $store->item_class(),                  $item_class, 'check for item class');
is( ref $item,                             $item_class, 'created item of correct class');
is( scalar (@a=$store->get_item_IDs()),              1, 'there is now one item');
is( ($store->get_item_IDs())[0],                   $ID, 'it has the right ID');
is( $store->get_item_by_ID($ID),                 $item, 'get the item with its id');
is( $store->get_ID_by_item($item),                 $ID, 'get ID with the item ref');
is( $store->remove_item($ID),                    $item, 'delete generated item');
is( $item->init(),                                   7, 'got init value that was parameter given to constructor');

# factory - selfmade call
my $cstore = Kephra::API::Object::Store->new($item_class, {}, 0, Kephra::API::Call->new('','TestClass->new(@_)'));
is( blessed($cstore),                           $class, 'created a store object with self made factory call');
($item, $ID)  = $cstore->new_item([2]);
is( ref $item,                             $item_class, 'create item with self made call');
is( scalar (@a=$cstore->get_item_IDs()),             1, 'there is now again one item');
is( ($cstore->get_item_IDs())[0],                  $ID, 'it has the right ID');
is( $cstore->get_item_by_ID($ID),                $item, 'get the item with its id');
is( $cstore->get_ID_by_item($item),                $ID, 'get ID with the item ref');
is( $cstore->remove_item($ID),                   $item, 'delete generated item');
is( $item->init(),                                   2, 'got init value of constructor');

# factory - selfmade template
my $factory = Kephra::API::Call::Template->new('', 'TestClass->new($_[0]', ')');
my $tstore = Kephra::API::Object::Store->new($item_class,{}, 0, $factory);
is( blessed($tstore),                           $class, 'created a store object with self made factory template');
($item, $ID)  = $tstore->new_item([12],['', '+2']);
is( ref $item,                             $item_class, 'create item with self made call');
is( scalar (@a=$tstore->get_item_IDs()),             1, 'there is now again one item');
is( ($tstore->get_item_IDs())[0],                  $ID, 'it has the right ID');
is( $tstore->get_item_by_ID($ID),                $item, 'get the item with its id');
is( $tstore->get_ID_by_item($item),                $ID, 'get ID with the item ref');
is( $tstore->remove_item($ID),                   $item, 'delete generated item');
is( $item->init(),                                  14, 'got init value of constructor');

# factory - selfmade dynacall
$factory = Kephra::API::Call::Dynamic->new('', Kephra::API::Call->new('','TestClass->new(@_)'), '$ref->run(@_)');
my $dcstore = Kephra::API::Object::Store->new($item_class, {}, 0, $factory);
is( blessed($dcstore),                          $class, 'created a store object with self made factory dynacall');
($item, $ID)  = $dcstore->new_item([8]);
is( ref $item,                             $item_class, 'create item with self made call');
is( scalar (@a=$dcstore->get_item_IDs()),            1, 'there is now again one item');
is( ($dcstore->get_item_IDs())[0],                 $ID, 'it has the right ID');
is( $dcstore->get_item_by_ID($ID),               $item, 'get the item with its id');
is( $dcstore->get_ID_by_item($item),               $ID, 'get ID with the item ref');
is( $dcstore->remove_item($ID),                  $item, 'delete generated item');
is( $item->init(),                                   8, 'got init value of constructor');

# factory - selfmade dynatemplate
$factory = Kephra::API::Call::Dynamic::Template->new('',Kephra::API::Call->new('','TestClass->new(@_)'), '$ref->run($_[0]', ')');
my $dtstore = Kephra::API::Object::Store->new($item_class, {}, 0, $factory);
is( blessed($dtstore),                          $class, 'created a store object with self made factory dynacall');
($item, $ID)  = $dtstore->new_item([23],['','', '-1']);
is( ref $item,                             $item_class, 'create item with self made call');
is( scalar (@a=$dtstore->get_item_IDs()),            1, 'there is now again one item');
is( ($dtstore->get_item_IDs())[0],                 $ID, 'it has the right ID');
is( $dtstore->get_item_by_ID($ID),               $item, 'get the item with its id');
is( $dtstore->get_ID_by_item($item),               $ID, 'get ID with the item ref');
is( $dtstore->remove_item($ID),                  $item, 'delete generated item');
is( $item->init(),                                  22, 'got init value of constructor');


# error messages
is(Kephra::API::Object::Store->new(1,2,3,4,5), undef, 'too many params for new');
like( pop(@error),           qr/one to four parameter/, 'error message for too many params to new method');
is(Kephra::API::Object::Store->new(),            undef, 'not enough params for new');
like( pop(@error),           qr/one to four parameter/, 'error message for too many params to new method');
is(Kephra::API::Object::Store->new('T'),         undef, 'T is not an loaded package');
like( pop(@warning),                    qr/not loaded/, 'warning message for missing package');
is(Kephra::API::Object::Store->new($item_class, 0),   undef, 'second parameter has to be hasref');
like( pop(@error),                qr/second parameter/, 'error message for bad second parameter');
is(Kephra::API::Object::Store->new($item_class,{'nomethod'=>''}), undef, 'this getter does not exist');
like( pop(@warning),                     qr/no method/, 'warn message for missing item getter');
is(Kephra::API::Object::Store->new($item_class,{get=>'nomethod'}), undef, 'this setter does not exist');
like( pop(@warning),                     qr/no method/, 'warn message for missing item setter');
is(Kephra::API::Object::Store->new($item_class,{},0,[]), undef, 'bad factory');
like( pop(@error),                    qr/factory type/, 'error message for wrong factory type');

is( $store->new_item(1,2,3),                          undef, 'too many parameter for new item method');
like( pop(@error),          qr/need one to three parameter/, 'got error that text object could not be added');
is( $store->new_item('1'),                            undef, 'item factory params have to come in a array ref, not text');
like( pop(@error),                qr/in an array reference/, 'got error because item gen factory did not get params in array');
is( $store->new_item({}),                             undef, 'item factory params have to come in a array ref, not hash');
like( pop(@error),                qr/in an array reference/, 'got error because item gen factory did not get params in array');
is( $store->new_item([],'1'),                         undef, 'item template params have to come in a array ref, not text');
like( pop(@error),                qr/in an array reference/, 'got error because item gen templates did not get params in array');
is( $store->new_item([],{}),                          undef, 'item template params have to come in a array ref, not hash');
like( pop(@error),                qr/in an array reference/, 'got error because item gen templates did not get params in array');

is( scalar (@a=$store->get_item_IDs()),                   0, 'store is empty');
is( $store->add_item('text'),                         undef, 'could not add text');
like( pop(@error),                   qr/no object of class/, 'got error that text object could not be added');
is( scalar (@a=$store->get_item_IDs()),                   0, 'store still empty');
is( $store->add_item([]),                             undef, 'could not add array ref');
like( pop(@error),                   qr/no object of class/, 'got error that array object could not be added');
is( scalar (@a=$store->get_item_IDs()),                   0, 'store still empty and without refs');
is( $store->add_item($store),                         undef, 'could not add store object');
like( pop(@error),                   qr/no object of class/, 'got error that object of not class could not be added');
is( scalar (@a=$store->get_item_IDs()),                   0, 'store still empty and without object');

is( $store->remove_item(12),                          undef, 'try to remove a not stored object by unused ID');
like( pop(@warning),                      qr/is not in use/, 'got warning that item ID could not be found');
is( $store->remove_item(TestClass->new()),            undef, 'try to remove a not stored object by ref');
like( pop(@warning),                    qr/not stored here/, 'got warning that item is not in store');

is( $store->delegate_method(),                        undef, 'not enough parameter for method delegate_method');
like( pop(@error),               qr/at least one parameter/, 'error says method delegate_method got not enough params');
is( $store->delegate_method('invented'),              undef, 'try delegate to not exisiting method');
like( pop(@error),                        qr/has no method/, 'error says method delegate_method tried call none existing method');


is( $store->get_item_by_atttibute(12),                undef, 'not enough parameter for method list_item_by_atttibute');
like( pop(@error),              qr/need only two parameter/, 'error says list_item_by_atttibute got not enough params');
is( $store->get_item_by_atttibute(1,2,3),             undef, 'too much parameter');
like( pop(@error),              qr/need only two parameter/, 'error says list_item_by_atttibute got tooo much params');
is( $store->get_item_by_atttibute('get',2),           undef, 'store has no registered getter');
like( pop(@warning),               qr/no registered getter/, 'got warning because no getter are registered in this store');


is( $store->has_history(),                                0, 'this store has no history');
is( $store->get_latest_item(1,2),                     undef, 'too many parameter');
like( pop(@error),     qr/need only one optional parameter/, 'error says need less parameter');
is( $store->get_latest_item(1),                       undef, 'can not call get_latest_item with one parameter, store has no history');
like( pop(@warning),                         qr/no history/, 'warning because call get_latest_item on store with no history');
is( $store->get_latest_item(),                        undef, 'can not call get_latest_item without params, store has no history');
like( pop(@warning),                         qr/no history/, 'warning because call get_latest_item on store with no history');
is( $store->use_item(1,2),                            undef, 'too many parameter');
like( pop(@error         ),          qr/need one parameter/, 'error says need one, not two');
is( $store->use_item(1),                              undef, 'can not call use_item, store has no history');
like( pop(@warning),                         qr/no history/, 'warning because call use_item on store with no history');

exit 0;

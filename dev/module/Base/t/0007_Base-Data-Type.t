#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}


package TypeTester; 
use Kephra::Base::Data::Type qw/:all/;
use Test::More tests => 60;

my $btclass = 'Kephra::Base::Data::Type::Basic';
my $ptclass = 'Kephra::Base::Data::Type::Parametric';
my $stclass = 'Kephra::Base::Data::Type::Store';


my $std  = Kephra::Base::Data::Type::standard;
my $share = Kephra::Base::Data::Type::shared;

is(ref $std,                               $stclass,            'standard types are in store');
is($std,  Kephra::Base::Data::Type::Standard::store,            'standard types are the official');
is(ref $share,                             $stclass,            'shared types are in store');
is(Kephra::Base::Data::Type::shared->is_open,'open',            'shared type store is permanently "open"');


my $Tdef = {name=> 'digit', help => 'single digit', code => '$value =~ /^\d$/', default => 0};
my $Tdig = Kephra::Base::Data::Type::create( $Tdef );
my $Tpdef = {name=> 'str', help => 'string of presctibed length', code => 'length $value <= $param', parent => 'str', parameter => {name=>'length', parent => $Tdig}};
my $Tstrl = Kephra::Base::Data::Type::create( $Tpdef );

my $Tstr = {name=> 'str', help => 'string', code => 'not ref $value', default => ''};
my $Tref = {name=> 'ref',   help => 'reference', code => 'ref $value', default => []};
my $store = Kephra::Base::Data::Type::Store->new();
$store->add_type($Tref);
$store->add_shortcut('basic','ref','_');
my $Tpref = {name=> 'ref', help => 'reference', code => 'ref $value eq $param', default => [], parent =>'ref', parameter => {parent => $Tstr, default => 'ARRAY', name =>'name'}};
$store->add_type( Kephra::Base::Data::Type::create($Tpref,'', $store) );
$store->add_shortcut('param','ref','_');


is(ref $Tdig,                              $btclass,            'could create basic type');
is(ref $Tstrl,                             $ptclass,            'could create parametric type');
is(ref create_type($Tdef),                 $btclass,            'sub symbol "create_type" imported as alias for ::Type::create, created basic type object');
is(ref create_type($Tpdef),                $ptclass,            'create_type: created parametric type from def , substituted parent type name with type standard object');
$share->add_type( $Tdig );
$share->add_type( $Tstrl );
$share->add_shortcut('basic','digit','D');
$share->add_shortcut('param','str','~');
$Tpdef = {name=> 'str', help => 'string of presctibed length', code => 'length $value <= $param', parent => 'str', parameter => {name=>'length', parent => 'digit'}};
is(ref Kephra::Base::Data::Type::create($Tpdef), '',            'not created type "str of length", parameter parent type "digit" was not in standard store');
is(ref create_type($Tpdef),                      '',            'create_type: not created type "str of length", parameter parent type "digit" was not in standard store');
is(ref Kephra::Base::Data::Type::create($Tpdef,'all'), $ptclass,'created type "str of length", parameter parent type "digit" was in shared store');
is(ref create_type($Tpdef,'all'),          $ptclass,            'create_type: created type "str of length", parameter parent type "digit" was in shared store');

is(Kephra::Base::Data::Type::is_known('int'),            1,      'a standard basic type is known');
is(Kephra::Base::Data::Type::is_known(['index','array']),1,      'a standard parametric type is known');
is(Kephra::Base::Data::Type::is_known('digit'),          0,      'a shared basic type is not known without additional argument');
is(Kephra::Base::Data::Type::is_known('digit', 1),       1,      'a shared basic type is known with additional argument');
is(Kephra::Base::Data::Type::is_known(['str','length']), 0,      'a shared parametric type is not known without additional argument');
is(Kephra::Base::Data::Type::is_known(['str','length'],1),1,     'a shared parametric type is known with additional argument');
is(is_type_known('int'),                                 1,      'sub symbol "is_type_known" imported and works on standard basic type');
is(is_type_known(['index','array']),                     1,      'sub symbol "is_type_known" imported and works on standard parametric type');
is(is_type_known('digit'),                               0,      'is_type_known: a shared basic type is not known without additional argument');
is(is_type_known('digit', 'shared'),                     1,      'is_type_known: a shared basic type is known with additional argument');
is(is_type_known(['str', 'length']),                     0,      'is_type_known: a shared parametric type is not known without additional argument');
is(is_type_known(['str', 'length'],'shared'),            1,      'is_type_known: a shared parametric type is known with additional argument');
is(is_type_known('int', 1),                              1,      'found standard type "int", even if added shared types');
is(is_type_known('int', 1, $store),                      1,      'found standard type "int", even if added store and shared types');
is(is_type_known('digit', 1, $store),                    1,      'found shared type "digit", even if added store');
is(is_type_known('ref', 1, $store),                      1,      'found class type "ref" with shared types store');
is(is_type_known('ref', 0, $store),                      1,      'found class type "ref" with shared types store');
is(is_type_known('ref', 1 ),                             0,      'not found class type "ref" in standard or shared type store');
is(is_type_known(['ref','name'], 1, $store),             1,      'found class type "ref of name" even with shared types store');
is(is_type_known(['ref','name'], 0, $store),             1,      'found class type "ref of name" even without shared types store');
is(is_type_known(['ref','name'], 1),                     0,      'not found class type "ref of name" in standard or shared type store');

is(Kephra::Base::Data::Type::resolve_shortcut('basic','+'),   'num',  'resolve standard type shortcut "+"');
is(resolve_type_shortcut('basic','+', 1, $store),             'num',  'resolve standard type shortcut "+" even when looking at shared types and class types with symbol shortcut: resolve_type_shortcut');
is(resolve_type_shortcut('basic','D' ),                          '',  'don\'t resolve shared type shortcut "D" when only looking in standard types');
is(resolve_type_shortcut('basic','D', 1),                   'digit',  'resolve shared type shortcut "D"');
is(resolve_type_shortcut('basic','D', 1, $store),           'digit',  'resolve shared type shortcut "D" also with additional class types lookup');
is(resolve_type_shortcut('basic','_', 1),                        '',  'not resolve class type shortcut "_"');
is(resolve_type_shortcut('basic','_', 0, $store),             'ref',  'resolve class type shortcut "_"');
is(resolve_type_shortcut('param','I', 1, $store),           'index',  'resolve shortcut "I" of standard parametric type');
is(resolve_type_shortcut('param','~', 1 ),                    'str',  'resolve shortcut "~" of shared parametric type');
is(resolve_type_shortcut('param','_', 1 ),                       '',  'not resolve shortcut "_" of parametric class type');
is(resolve_type_shortcut('param','_', 1, $store ),            'ref',  'resolve shortcut "_" of parametric class type');

is(Kephra::Base::Data::Type::check('int', 5),         '',       'can check basic standard type, correct positive');
ok(Kephra::Base::Data::Type::check('int', 2.2),                 'can check basic standard type, correct negative');
ok(Kephra::Base::Data::Type::check('digit', 5),                 'can not check basic shared type without additional arument');
is(Kephra::Base::Data::Type::check('digit', 5, 'all'),'',       'can check basic shared type with additional arument, correct positive');
ok(Kephra::Base::Data::Type::check('digit',11, 'all'),          'can check basic shared type with additional arument, correct ngative');
is(check_type('int', 5),                              '',       'sub symbol "check_type" imported as alias for: ::Type::check');
ok(check_type('int', 2.2),                                      'check_type: can check basic standard type, correct negative');
ok(check_type('digit', 5),                                      'check_type: can not check basic shared type without additional arument');
is(check_type('digit', 5, 'all'),                     '',       'check_type: can check basic shared type with additional arument, correct positive');
ok(check_type('digit',11, 'all'),                               'check_type: can check basic shared type with additional arument, correct ngative');

is('int' ~~ [Kephra::Base::Data::Type::guess(5)],      1,       'standard type "int" could be guessed from value: 5');
is('digit' ~~ [Kephra::Base::Data::Type::guess(5)],   '',       'shared type "digit" could not be guessed from value: 5 without additional argument');
is('digit' ~~ [guess_type(5,'all')],                   1,       'shared type "digit" could be guessed from value: 5 wit additional argument');
is('int'   ~~ [guess_type(5)],                         1,       'sub symbol "guess_type" imported, guessed "int" from value 5 too');
is('digit' ~~ [guess_type(5)],                        '',       'guess_type: shared type "digit" could not be guessed from value: 5 without additional argument');
is('digit' ~~ [guess_type(5,'all')],                   1,       'guess_type: shared type "digit" could be guessed from value: 5 wit additional argument');


exit 0;

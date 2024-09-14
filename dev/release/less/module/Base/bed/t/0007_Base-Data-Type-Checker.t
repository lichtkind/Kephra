#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

package TypeTester; 
use Test::More tests => 200;

my $bclass  = 'Kephra::Base::Data::Type::Basic';
my $pclass  = 'Kephra::Base::Data::Type::Parametric';
my $tclass  = 'Kephra::Base::Data::Type::Set';
my $cclass  = 'Kephra::Base::Data::Type::Checker';


eval "use $cclass;";
is( $@, '',                                                               'loaded type checker package');

exit 0;

__END__

my $store = Kephra::Base::Data::Type::Store->new();
is( ref $store, $sclass,                                                  'could create a closable type store object');
is( $store->list_type_names('basic'),                      undef,         'no basic types can be listed');
is( $store->list_type_names('param'),                      undef,         'no parametric types can be listed');
is( $store->list_shortcuts('basic'),                       undef,         'no basic shortcut can be listed');
is( $store->list_shortcuts('param'),                       undef,         'no parametric shortcut can be listed');
is( $store->list_forbidden_shortcuts(),                    undef,         'no forbidden shortcut can be listed');
is( $store->guess_basic_type(''),                          undef,         'no types there to guess value from');
is( $store->is_open(),                                         1,         'newly made type store is open');
is( $store->is_type_known('superkalifrailistisch'),            0,         'check for unknown basic type');
is( $store->is_type_known('superkalifrailistisch', 'p'),       0,         'check for unknown parametric type');
is( $store->is_type_owned('superkalifrailistisch'),            0,         'caller does not own unknown basic type');
is( $store->is_type_owned('superkalifrailistisch', 'p'),       0,         'caller does not own unknown parametric type');
is( $store->get_type('superkalifrailistisch'),             undef,         'can not get unknown basic type');
is( $store->get_type('superkalifrailist','isch'),          undef,         'can not get unknown parametric type');
is( $store->is_type_known('superkalifrailistisch'),            0,         'get did not create a basic type entry');
is( $store->is_type_known('superkalifrailistisch', 'p'),       0,         'get did not create a prametric type entry');
is( $store->get_shortcut('basic','superkalifrailistisch'), undef,         'can not get shortcut from unknown basic type');
is( $store->get_shortcut('param','superkalifrailistisch'), undef,         'can not get shortcut from unknown parametric type');
is( $store->resolve_shortcut('basic','='),                 undef,         'can not resolve unknown shortcut for basic types');
is( $store->resolve_shortcut('param','='),                 undef,         'can not resolve unknown shortcut for parametric types');
is( $store->list_type_names('basic'),                      undef,         'list of basic types is still clean');
0;
is( $store->list_type_names('param'),                      undef,         'list of parametric types is still clean');
is( $store->list_type_names('param','a'),                  undef,         'list of known parameters of unknown param type is also clean');


my $Tval = Kephra::Base::Data::Type::Basic->new({name => 'value', help => 'defined value', code =>'defined $value', default => ''});
my $Tnref = Kephra::Base::Data::Type::Basic->new({name => 'no_ref', help => 'not a reference', code =>'not ref $value', parent => $Tval});

is( $store->is_type_known('value'),                            0,         'type is not known before creation');
is( $store->get_type('value'),                             undef,         'can not get type before creation');
is( ref $Tval,                                           $bclass,         'created a valid basic type');
is( $store->add_type($Tval),                                  '',         'could add basic type "value"');
is( $store->get_type('value'),                             $Tval,         'got same type object out by getter');
is( $store->is_type_known('value'),                            1,         'type "value" is known after addition');
is( $store->is_type_owned('value'),                            1,         'type "value" is owned by creator');
is( $store->check_basic_type('value', 1),                     '',         'type "value" can be checked, correct positive');
ok( $store->check_basic_type('value', undef),                             'type "value" can be chacked, correct negative');
my @list = $store->list_type_names('basic');
is( @list,                                                     1,         'can list now one basic type');
is( $list[0],                                            'value',         'new basic type "value" shows up in list');
is( $store->list_type_names('param'),                      undef,         'no parametric types can be listed');
@list = $store->guess_basic_type(1);
is( @list,                                                     1,         'can list now one type guess');
is( $list[0],                                            'value',         'new basic type "value" can be guessed');
is( $store->remove_type('value'),                          $Tval,         'could remove basic type "value"');
is( $store->get_type('value'),                             undef,         'type "value" is gone');
is( $store->is_type_known('value'),                            0,         'type "value" is unknown again');

is( $store->add_type({name => 'value', help => 'defined value', code =>'defined $value', default => 0}), '', 'could creade and add basic type "value" without parent');
is( ref $store->get_type('value'),                       $bclass,         'got basic type "value" object by getter');
is( $store->is_type_known('value'),                            1,         'type "value" is known after creation and addition');
is( $store->is_type_owned('value'),                            1,         'type "value" is owned by creator');
package Other;
use Test::More;
is( $store->is_type_owned('value'),                            0,         'type "value" is not owned by other pacjages');
package TypeTester; 
is( $store->check_basic_type('value', 'a'),                   '',         'type "value" can be checked, correct positive');
ok( $store->check_basic_type('value', undef),                             'type "value" can be checked, correct negative');
@list = $store->list_type_names('basic');
is( @list,                                                     1,         'can list now one basic type');
is( $list[0],                                            'value',         'new basic type "value" shows up in list');
is( $store->list_type_names('param'),                      undef,         'no parametric types can be listed');
@list = $store->guess_basic_type(1);
is( @list,                                                     1,         'can list now one type guess');
is( $list[0],                                            'value',         'new basic type "value" can be guessed');
is( ref $store->remove_type('value'),                    $bclass,         'could remove created basic type "value"');

is( $store->add_type($Tnref),                                 '',         'could and add basic type "no_ref" with none stored parent');
is( $store->is_type_known('no_ref'),                           1,         'type "no_ref" is known after creation and addition');
is( ref $store->get_type('no_ref'),                      $bclass,         'got basic type "no_ref" object by getter');
@list = $store->list_type_names('basic');
is( @list,                                                     1,         'can list now one basic type');
is( $list[0],                                            'no_ref',         'new basic type "value" shows up in list');
is( $store->check_basic_type('no_ref', 'a'),                  '',         'type "no_ref" can be checked, correct positive');
ok( $store->check_basic_type('no_ref', []),                               'type "no_ref" can be checked, correct negative');
is( $store->add_type({name => 'int', help => 'integer', code=> 'int($value) eq $value', default => 0, parent => $store->get_type('no_ref')},'#'),
                                                              '',         'could create and add basic type with stored parent and shortcut');
is( $store->is_type_known('int'),                              1,         'type "int" is known after creation and addition');
is( ref $store->get_type('int'),                         $bclass,         'got basic type "int" object by getter');
is( $store->check_basic_type('int', '-10'),                   '',         'type "int" can be checked, correct positive');
ok( $store->check_basic_type('int', 1.1),                                 'type "int" can be checked, correct negative');
is( $store->get_shortcut('no_ref','int'),                  undef,         'got shortcut of basic type "int"');
is( $store->get_shortcut('basic','int'),                     '#',         'got shortcut of basic type "int"');
is( $store->resolve_shortcut('basic','#'),                 'int',         'resolved shortcut of basic type "int"');
@list = $store->list_type_names('basic');
is( @list,                                                     2,         'can list now two basic types');
is( $list[0],                                              'int',         'new basic type "int" shows up in list');
is( $list[1],                                           'no_ref',         'new basic type "no_ref" shows up in list');
@list = $store->list_shortcuts('basic');
is( @list,                                                     1,         'can list now one basic shortcut');
is( $list[0],                                                '#',         'new shortcut of basic type "int" shows up in list');
is( $store->add_type({name => 'num', help => 'number', code=> 'looks_like_number($value)', default => 0, parent => $store->get_type('no_ref')}),
                                                              '',         'creaded and added basic type with stored parent and shortcut');
is( $store->add_shortcut('basic','num','+'),                  '',         'added shortcut to already known basic type "num"');
is( $store->get_shortcut('basic','num'),                     '+',         'got shortcut of basic type "num"');
is( $store->resolve_shortcut('basic','+'),                 'num',         'resolved shortcut of basic type "num"');
@list = $store->list_shortcuts('basic');
is( @list,                                                     2,         'can list now two basic shortcut');
is( $list[0],                                                '#',         'new shortcut of basic type "int" shows up in list');
is( $list[1],                                                '+',         'new shortcut of basic type "num" shows up in list');
is( $store->list_type_names('param'),                      undef,         'no parametric types can be listed');
is( $store->list_shortcuts('param'),                       undef,         'no parametric shortcut can be listed');
@list = $store->guess_basic_type(1);
is( @list,                                                     3,         'value "1" can be of three types');
is( 'int' ~~ [@list],                                          1,         'it can be "int"');
is( 'num' ~~ [@list],                                          1,         'it can be "num"');
is( 'no_ref' ~~ [@list],                                       1,         'it can be "no_ref"');
@list = $store->guess_basic_type(1.1);
is( @list,                                                     2,         'value "1.1" can be of two types');
is( $list[0],                                              'num',         '"num" is the most likly type');
@list = $store->guess_basic_type('c');
is( @list,                                                     1,         'value "c" can only be of one type');
is( $list[0],                                           'no_ref',         'it is basic type "no_ref"');
is( ref $store->remove_type('no_ref'),                    $bclass,        'could remove created basic type "no_ref"');
@list = $store->list_type_names('basic');
is( @list,                                                     2,         'can list now two basic types');
is( $list[0],                                              'int',         'new basic type "int" shows up in list');
is( $list[1],                                              'num',         'new basic type "num" shows up in list');
is( $store->remove_shortcut('basic','#'),                     '',         'removed shortcut of basic type "int"');
is( $store->get_shortcut('basic','int'),                   undef,         'basic type "int" has no more shortcut');
is( $store->resolve_shortcut('basic','#'),                 undef,         'resolved shortcut of basic type "int" has to be undef');
@list = $store->list_shortcuts('basic');
is( @list,                                                     1,         'one basic shortcut is left');
is( $list[0],                                                '+',         'it is the shortcut of basic type "num"');
is( ref $store->remove_type('num'),                      $bclass,         'removed basic type "num"');
is( $store->list_shortcuts('basic'),                       undef,         'no more shortcuts after deleting last type with shortcut');
@list = $store->list_type_names('basic');
is( @list,                                                     1,         'can list only one basic type name');
is( $list[0],                                              'int',         'new basic type "int" shows up in list');


my $Tindex_def = {name => 'index', help => 'index of array', code =>'return "value $value is out of range" if $value >= @$param', default => 0, parent => $store->get_type('int'), 
                  parameter => {name => 'array', help => 'array reference', code => 'ref $value eq "ARRAY"', default => [1]}};
is( $store->add_type($Tindex_def, '^'),                       '',         'created and added parametric type with stored parent and shortcut');
is( ref $store->get_type('index','array'),               $pclass,         'got parametric type "index" of "array" object by getter');
is( $store->is_type_known('index','array'),                    1,         'parametric type "index" of "array" is known');
is( $store->is_type_owned('index','array'),                    1,         'parametric type "index" of "array" is owned by caller');
package Other;
is( $store->is_type_owned('index','array'),                    0,         'parametric type "index" of "array" is not owned by caller');
package TypeTester; 
is( $store->get_shortcut('param','index'),                   '^',         'got shortcut of parametric type "index" of "array"');
is( $store->resolve_shortcut('param','^'),               'index',         'resolved shortcut of parametric type "index" of "array"');
@list = $store->list_type_names('param');
is( @list,                                                     1,         'can list one parametric type');
is( $list[0],                                            'index',         'new basic type "int" shows up in list');
@list = $store->list_type_names('param', 'int');
is( @list,                                                     0,         'basic type does not have any parameter types');
@list = $store->list_type_names('param', 'index');
is( @list,                                                     1,         'parameter of type "index" can have one type');
is( $list[0],                                            'array',         'new basic type "int" shows up in list');
@list = $store->list_shortcuts('param');
is( @list,                                                     1,         'one parametric shortcut is in store');
is( $list[0],                                                '^',         'it is the shortcut of parametric type "index of array"');
is( $store->add_type({name => 'int_pos', help => 'positive', code=> '$value >= 0', parent => $store->get_type('int')}), '', 'crated basic type "pos_int"');
is( ref $store->remove_type('int'),                      $bclass,         'removed basic type "int", parent of index');
is( $store->check_param_type('index', 'array', 2, [1,2,3]),   '',         'type "index of array" can be checked, correct positive');
ok( $store->check_param_type('index', 'array', 3, [1,2,3]),               'type "value" can be checked, correct negative');
is( ref $store->remove_type('index', 'array'),           $pclass,         'removed parametric type "index of array"');
is( $store->list_type_names('param'),                      undef,         'no parametric types can be listed');
is( $store->list_type_names('param','index'),              undef,         'no parameters of deleted type can be listed');
is( $store->list_shortcuts('param'),                       undef,         'no parametric shortcut can be listed');
is( $store->add_type({name => 'array_ref', help => 'array reference', code => 'ref $value eq "ARRAY"', default => []}), '', 'crated basic type "array_ref"');
is( $store->add_type({name => 'array',  parent => $store->get_type('array_ref'), default => [1]}), '', 'crated basic type "array"');


$Tindex_def = {name => 'index', help => 'index of array', code =>'return "value $value is out of range" if $value >= @$param', parent => $store->get_type('int_pos'), 
                                parameter => {name => 'array', parent => $store->get_type('array_ref'), default => [1]}};
is( $store->add_type($Tindex_def),                            '',         'created and added parametric type "index of array" with stored parent and stored parameter parent');
ok( $store->add_type($Tindex_def),                                        'can not add same parametric type twice');
is( $store->add_shortcut('param', 'index', "'"),              '',         'added shortcut to parametric type "index of array"');
is( $store->get_shortcut('param', 'index'),                  "'",         'got shortcut of parametric type "index" of "array"');
is( $store->resolve_shortcut('param',"'"),               'index',         'resolved shortcut of parametric type "index" of "array"');
@list = $store->list_type_names('param');
is( @list,                                                     1,         'can list one parametric type');
is( $list[0],                                            'index',         'new basic type "int" shows up in list');
@list = $store->list_type_names('param', 'int');
is( @list,                                                     0,         'basic type does not have any parameter types');
@list = $store->list_type_names('param', 'index');
is( @list,                                                     1,         'parameter of type "index" can have one type');
is( $list[0],                                            'array',         'new basic type "int" shows up in list');
@list = $store->list_shortcuts('param');
is( @list,                                                     1,         'one parametric shortcut is in store');
is( $list[0],                                                "'",         'it is the shortcut of parametric type "index of array"');
is( $store->remove_shortcut('param', "'"),                    '',         'removed shortcut of parametric type "index of array"');
is( $store->list_shortcuts('param'),                       undef,         'no more parametric type shortcut can be listed');
is( $store->list_shortcuts('basic'),                       undef,         'no basic type shortcut can be listed');
is( $store->check_param_type('index', 'array', 2, [1,2,3]),   '',         'type "index of array" can be checked, correct positive');
is( ref $store->remove_type('index', 'array'),           $pclass,         'removed parametric type "index of array"');


$Tindex_def = {name => 'index', help => 'index of array', code =>'return "value $value is out of range" if $value >= @$param', 
                                parent => $store->get_type('int_pos'), parameter => $store->get_type('array')};
is( $store->add_type($Tindex_def, ':'),                       '',         'created and added parametric type "index of array" with stored parent and parameter');
is( $store->check_param_type('index', 'array', 2, [1,2,3]),   '',         'type "index of array" can be checked, correct positive');
is( $store->add_type({name => 'hash', help => 'hash reference', code => 'ref $value eq "HASH"', default => { '' => 1}}), '', 'crated basic type "hash"');
is( $store->add_type({name => 'str',  help => 'string', code => 'defined $value and not ref $value', default => '' }), '', 'crated basic type "str"');
$Tindex_def = {name => 'index', help => 'index of hash', code =>'return "key $value does not exists" if not exists $param->{$value}',
                                parent => $store->get_type('str'), parameter => $store->get_type('hash')};
is( $store->add_type($Tindex_def),                            '',         'created and added parametric type "index of hash" with stored parent and parameter');
@list = $store->list_type_names('param');
is( @list,                                                     1,         'can list one parametric type');
is( $list[0],                                            'index',         'new basic type "int" shows up in list');
@list = $store->list_type_names('param', 'index');
is( @list,                                                     2,         'parameter of type "index" can have two types');
is( $list[0],                                            'array',         'one is array');
is( $list[1],                                             'hash',         'other is hash');
is( ref $store->remove_type('index', 'array'),           $pclass,         'removed parametric type "index of array"');
@list = $store->list_type_names('param');
is( @list,                                                     1,         'can still list one parametric type');
is( $list[0],                                            'index',         'new basic type "int" shows up in list');
@list = $store->list_type_names('param', 'index');
is( @list,                                                     1,         'parameter of type "index" can have again one type');
is( $list[0],                                             'hash',         'other is hash');
@list = $store->list_shortcuts('param');
is( @list,                                                     1,         'one parametric shortcut is in store');
is( $list[0],                                                ":",         'it is the shortcut of parametric type "index of hash"');
is( $store->get_shortcut('param', 'index'),                  ":",         'got shortcut of parametric type "index" of "array"');
is( $store->resolve_shortcut('param',":"),               'index',         'resolved shortcut of parametric type "index" of "array"');
@list = $store->list_type_names('basic');
is( @list,                                                     5,         'currently 5 basic types stored');
is( $list[0],                                            'array',         '"array"');
is( $list[1],                                        'array_ref',         '"array ref"');
is( $list[2],                                             'hash',         '"hash"');
is( $list[3],                                          'int_pos',         '"int_pos"');
is( $list[4],                                              'str',         '"str"');
@list = $store->guess_basic_type(1);
is( @list,                                                     2,         'value "1" can be of two types');
is( $list[0],                                          'int_pos',         '"int_pos" is the most specific type');
is( $list[1],                                              'str',         '"str" is a less specific but acceptable type');

$store->add_shortcut('basic','array','@');
@list = $store->list_shortcuts('basic');
is( @list,                                                     1,         'one basic type shortcut is known in store');
is( $list[0],                                                "@",         'it is the shortcut of parametric type "index of hash"');

my $state = $store->state;
is( ref $state,                                          'HASH',          'got state HASH of type store');
is( ref $store->remove_type('str'),                      $bclass,         'removed type "str"');
is( ref $store->remove_type('index', 'hash'),            $pclass,         'removed type "index of hash"');
my $old_store = Kephra::Base::Data::Type::Store->restate($state);
is( ref $old_store,                                      $sclass,         'restored store object from state HASH');
is( $old_store->is_type_known('index','hash'),                 1,         'parametric type "index" of "hash" is known again');
is( $old_store->is_type_known('str'),                          1,         'basic type "str" is known again');
is( $old_store->check_basic_type('str', 'hash'),              '',         'basic type "str" can be checked, correct positive');
ok( $old_store->check_basic_type('str', undef),                           'basic type "str" can be checked against undef , correct negative');
ok( $old_store->check_basic_type('str', []),                              'basic type "str" can be checked against a ref, correct negative');
is( $old_store->check_param_type('index', 'hash', 'a', {a=>1}), '',       'parametric type "index of hash" can be checked, correct positive');
ok( $old_store->check_param_type('index', 'hash', 'b', {a=>1}),           'parametric type "index of hash" can be checked, correct negative');
ok( $old_store->check_param_type('index', 'hash', [],  {a=>1}),           'parametric type "index of hash" can be checked, correct negative - value does not match evem parent type');
ok( $old_store->check_param_type('index', 'hash', 'a', undef),            'parametric type "index of hash" can be checked, correct negative - bad parameter');
is( $old_store->is_open(),                                       1,       'copied store is open');
$old_store->close();
is( $old_store->is_open(),                                       0,       'copied store was just closed');
is( $old_store->is_open(),                                       0,       'copied store was just closed');
is (Kephra::Base::Data::Type::Store->restate($old_store->state)->is_open(), 0, 'copy stays closed');

$Tindex_def = {name => 'index', help => 'index of array', code =>'return "value $value is out of range" if $value >= @$param', 
                                parent => $store->get_type('int_pos'), parameter => $store->get_type('array')};
is( ref $store->add_type($Tindex_def, '@'),                   '',         'add parametric type "index of array"');
$Tindex_def = {name => 'index', help => 'index of hash', code =>'return "key $value does not exists" if not exists $param->{$value}',
                                parent => $store->get_type('str'), parameter => $store->get_type('hash')};
is( $store->is_open(),                                         1,         'store is open');
is( $store->close(),                                           1,         'closing store');
is( $store->is_open(),                                         0,         'store is closed');
is( $store->close(),                                           0,         'closed store keeps being closed');
ok( $store->add_type({name => 'str',  help => 'string', code => 'defined $value and not ref $value', default => '' }), 'can not add basic type to closed store');
is( $store->is_type_known('str'),                              0,         'basic type "str" is not known');
ok( $store->add_type($Tindex_def),                                        'can not add parametric type to closed store');
is( $store->is_type_known('index', 'hash'),                    0,         'parametric type "index fo hash" is not known');
ok( $store->add_shortcut('hash','%'),                                     'can not add shortcut to closed store');
is( $store->get_shortcut('%'),                             undef,         'shortcut % was not added');
ok( $store->remove_type('int_pos'),                                       'can not remove basic type from closed store');
is( $store->is_type_known('int_pos'),                          1,         'basic type "int_pos" is still there');
ok( $store->remove_type('index', 'array'),                                'can not remove parametric type "index of array" from closed store');
is( $store->is_type_known('index', 'array'),                   1,         'parametric type "index of array" is still there');
ok( $store->remove_shortcut('basic', '@'),                                'can not remove basic type shortcut from closed store');
is( $store->resolve_shortcut('basic', '@'),              'array',         'shortcut of basic type "array" is still there');
ok( $store->remove_shortcut('param', '@'),                                'can not remove parametric type shortcut from closed store');
is( $store->resolve_shortcut('param','@'),               'index',         'resolved shortcut of parametric type "index" of "array" is still there');

my $ostore = Kephra::Base::Data::Type::Store->new('open');
is( ref $ostore,                                         $sclass,         'created open strore');
is( $ostore->is_open(),                                   'open',         'store is open');
is( $ostore->close(),                                          0,         'open store can not be closed');
is( $ostore->is_open(),                                   'open',         'store is still open');
is( $ostore->add_type({name => 'any',  help => 'anything', code => '1', default => 1 }), '', 'added basic type "str" to open store');
is( $ostore->add_type({name => 'str',  help => 'string',   code => 'defined $value and not ref $value', default => '' }), '', 'added basic type "str" to open store');
ok( $ostore->add_type({name => 'str',  help => 'string',   code => 'defined $value and not ref $value', default => '' }),  'can not add same basic type twice');
is( $ostore->add_type({name => 'ref',  help => 'reference',code => 'ref $value eq $param', default => '', parent => $ostore->get_type('any'), parameter => {name => 'name', parent => $ostore->get_type('str')} }),
                                                              '',         'added parametric type "ref" to open store');
is( $ostore->is_type_known('str'),                             1,         'basic type "str" is now known');
is( $ostore->is_type_known('ref', 'name'),                     1,         'parametric type "ref of name" is now known');
is( $ostore->get_shortcut('basic','str'),                  undef,         'basic type "str" has still no shortcut');
is( $ostore->get_shortcut('param','ref'),                  undef,         'parametric type "ref of name" has still no shortcut');
is( $ostore->add_shortcut('basic', 'str','~'),                '',         'added shortcut to basic type "str" in open store');
is( $ostore->add_shortcut('parametric', 'ref','/'),           '',         'added shortcut to parametric type "ref of name" in open store');
ok( $ostore->add_shortcut('basic', 'str','~'),                            'can not add shortcut to basic type "str" twice');
ok( $ostore->add_shortcut('parametric', 'ref','/'),                       'can not add shortcut to parametric type "ref of name" twice');
ok( $ostore->add_shortcut('basic', 'str','.'),                            'can not add different shortcut to basic type "str"');
ok( $ostore->add_shortcut('parametric', 'ref','='),                       'can not add different shortcut to parametric type "ref of name"');
is( $ostore->resolve_shortcut('basic', '~'),               'str',         'shortcut of basic type "str" could be resolved');
is( $ostore->resolve_shortcut('parametric', '/'),          'ref',         'shortcut of parametric type "ref of name" could be resolved');
is( $ostore->resolve_shortcut('basic', '.'),               undef,         'uselessly added shortcut of basic type "str" can not be detected');
is( $ostore->resolve_shortcut('parametric', '='),          undef,         'uselessly added shortcut of parametric type "ref of name" can not be detected');
ok( $ostore->add_shortcut('basic', 'one','.'),                            'can not add shortcut to unknown basic type');
ok( $ostore->add_shortcut('parametric', 'two','='),                       'can not add shortcut to unknown parametric type');
is( $ostore->resolve_shortcut('basic', '.'),               undef,         'uselessly added shortcut of basic type "str" can not be detected');
is( $ostore->resolve_shortcut('parametric', '='),          undef,         'uselessly added shortcut of parametric type "ref of name" can not be detected');
is( $ostore->remove_shortcut('basic', '~'),                   '',         'removed shortcut of basic type "str" from open store');
is( $ostore->remove_shortcut('parametric', '/'),              '',         'removed shortcut of parametric type "ref of name" from open store');
is( $ostore->resolve_shortcut('basic', '~'),               undef,         'shortcut of basic type "array" could not be resolved');
is( $ostore->resolve_shortcut('parametric', '/'),          undef,         'shortcut of parametric type "ref of name" could not be resolved');
is( $ostore->get_shortcut('basic','str'),                  undef,         'basic type "str" has no shortcut again');
is( $ostore->get_shortcut('param','ref'),                  undef,         'parametric type "ref of name" has no shortcut again');

is( $ostore->list_forbidden_shortcuts(),                   undef,         'no forbidden shortcut can be listed');
is( $ostore->forbid_shortcuts(qw/( )/),                       '',         'forbid round braces as shortcuts');
@list = $ostore->list_forbidden_shortcuts();
is( @list,                                                     2,         'now 2 forbidden shortcuts listed');
is( $list[0],                                                '(',         'one is )');
is( $list[1],                                                ')',         'other is (');
is( $ostore->forbid_shortcuts(qw/-/),                         '',         'forbid third shortcuts');
@list = $ostore->list_forbidden_shortcuts();
is( @list,                                                     3,         'now 3 forbidden shortcuts listed');
ok( $ostore->add_type({name => 'int',  help => 'integer', code => 'int $value == $value', default => 0 }, '-'), 'could not add basic type "int" due forbidden shortcut');
is( $ostore->is_type_known('int'),                             0,         'basic type "int" is not known yet');
is( $ostore->add_type({name => 'int',  help => 'integer', code => 'int $value == $value', default => 0 }),'',   'could add basic type "int" without forbidden shortcut');
is( $ostore->is_type_known('int'),                             1,         'basic type "int" is known');
ok( $ostore->add_shortcut('int', '-'),                                    'could not add forbidden shortcut to basic type "int"');
is( $ostore->get_shortcut('basic', 'int'),                 undef,         'basic type "int" has still no shortcut');

exit 0;

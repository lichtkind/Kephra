#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type qw/:all/;
use Test::More tests => 126;

is( check_type('value',1),             '', 'recognize 1 as value');
is( check_type('value',0),             '', 'recognize 0 as value');
is( check_type('value',''),            '', 'recognize empty string as value');
is( check_type('value','d'),           '', 'recognize letter value');
ok( check_type('value',[]),                'recognize that a ref is not a value');

is( check_type('bool',1),              '', 'recognize boolean value true');
is( check_type('bool',0),              '', 'recognize boolean value false');
ok( check_type('bool',''),                 'empty is not boolean');
ok( check_type('bool','der'),              'string is not boolean');
ok( check_type('bool',2),                  'int is not boolean');
ok( check_type('bool',2.3),                'float is not boolean');
ok( check_type('bool',[]),                 'ref is not boolean');

is( check_type('num',22),              '', 'recognize an integer as a number');
is( check_type('num',1.5),             '', 'recognize small float as number');
is( check_type('num',0.1e-5),          '', 'recognize scientific number');
ok( check_type('num','das'),               'string is not a number');
ok( check_type('num', sub{}),              'coderef is not a number');
is( Kephra::Base::Data::Type::get_default_value('num'), 0, 'got default number');

is( check_type('num+',1.5),            '', 'recognize positive number');
is( check_type('num+',0),              '', 'zero is positive number');
ok( check_type('num+',-1.5),               'a negative is not a positive number');
ok( check_type('num+','das'),              'string is not a positive number');

is( check_type('int',  5),             '', 'recognize integer');
is( check_type('int',-12),             '', 'recognize negative integer');
is( check_type('int',1_2e12),          '', 'recognize huge integer');
ok( check_type('int',1.5),                 'real is not an integer');
ok( check_type('int','das'),               'string is not an integer');
ok( check_type('int',{}),                  'hash ref is not an integer');

is( check_type('int+',1),              '', 'recognize positive int');
is( check_type('int+',0),              '', 'zero is positive int');
ok( check_type('int+',-1),                 'a negative is not a positive int');
ok( check_type('int+','das'),              'string is not a positive int');

is( check_type('int++',1),             '', 'one is a stricly positive number');
ok( check_type('int++',0),                 'zero is not a stricly positive number');

is( check_type('str', 'das'),          '', 'recognize string');
is( check_type('str', 5),              '', 'numbers can be strings');
ok( check_type('str', {}),                 'ref ist not a string');


is( check_type('str+','das'),          '', 'recognize none empty string');
ok( check_type('str+', ''),                'this is not a none empty string');

is( check_type('str+uc', 'DAS'),       '', 'recognize upper case string');
ok( check_type('str+uc', 'DaS'),           'this is not an upper case string');
is( Kephra::Base::Data::Type::get_default_value('str+uc'), ' ', 'this type has no default');

is( check_type('str+lc', 'das'),       '', 'recognize lower case string');
ok( check_type('str+lc', 'DaS'),           'this is not an lower case string');


is( check_type('num',  1.5),           '', 'recognize number');
is( check_type('num+', 1.5),           '', 'recognize positive number');
is( check_type('int',    5),           '', 'recognize integer');
is( check_type('int+',   5),           '', 'recognize positive integer');

is( Kephra::Base::Data::Type::resolve_shortcut('~'), 'str+', 'resolved string shortcut');
is( Kephra::Base::Data::Type::resolve_shortcut('?'), 'bool', 'resolved boolean shortcut');
ok( ('~' ~~ [Kephra::Base::Data::Type::list_shortcuts()]), 'string shortcut gets listed');
ok( ('?' ~~ [Kephra::Base::Data::Type::list_shortcuts()]), 'boolean shortcut gets listed');


my @type = guess_type(5);
ok( !('bool' ~~ \@type),'5 is not an boolean');
ok( 'int' ~~ \@type,    '5 is an integer');
ok( 'int+' ~~ \@type,   '5 is a positive integer');
ok( 'int++' ~~ \@type,  '5 is a strictly positive integer');
ok( 'num' ~~ \@type,    '5 is a number');
ok( 'num+' ~~ \@type,   '5 is a positive number');
ok( 'str+' ~~ \@type,   '5 is none empty string');
ok( 'any' ~~ \@type,    '5 is a value');

@type = guess_type(0);
ok( 'bool' ~~ \@type,   '0 is a boolean');
ok( 'int' ~~ \@type,    '0 is an integer');
ok( 'int+' ~~ \@type,   '0 is a positive integer');
ok( 'num' ~~ \@type,    '0 is a number');
ok( 'num+' ~~ \@type,   '0 is a positive number');
ok( 'str+' ~~ \@type,   '0 is none empty string');
ok( 'any' ~~ \@type,    '0 is a value');

@type = guess_type('');
ok( !('bool' ~~ \@type), 'empty string is not a boolean');
ok( !('int' ~~ \@type),  'empty string is not an integer');
ok( !('num' ~~ \@type),  'empty string is not a number');
ok( !('str+' ~~ \@type), 'not empty string');
ok( 'any' ~~ \@type,     'empty string is a value');

@type = Kephra::Base::Data::Type::list_names();
ok( ('bool' ~~ \@type),  'bool type is known, list works');
ok( ('num' ~~ \@type),   'num type is known, list works');
ok( ('int' ~~ \@type),   'int type is known, list works');
ok( ('any' ~~ \@type),   'any type is known, list works');


package Typer;
use Test::More;

my $type_name = 'test_type';
is( Kephra::Base::Data::Type::is_known($type_name),   0, 'test type not present yet');
is( Kephra::Base::Data::Type::is_owned('bool'),       0, 'default type bool is not recognized as own my current package');
is( add($type_name, 'infive',sub{-5 < $_[0] and $_[0] < 5},2,'int', '-'),   1, 'added my custom type');

ok( ($type_name ~~ [Kephra::Base::Data::Type::list_names()]), 'new created type gets listed');
ok( ('-' ~~ [Kephra::Base::Data::Type::list_shortcuts()]), 'new created type shortcut gets listed');
is( Kephra::Base::Data::Type::resolve_shortcut('-'), $type_name, 'shortcut of new type can be resolved');
is( Kephra::Base::Data::Type::is_known($type_name),   1, 'test type is present now');
is( Kephra::Base::Data::Type::is_owned($type_name),   1, 'test type is recognized as owned by my current package');
is( Kephra::Base::Data::Type::is_standard($type_name), 0,'test type is not recognized as standard');
is( Kephra::Base::Data::Type::is_standard('int'),      1,'int is recognized as standard');
is( Kephra::Base::Data::Type::get_default_value($type_name),2,'got default value of self made type');
is( Kephra::Base::Data::Type::check($type_name,   1), '','test type accepts correctly');
ok( Kephra::Base::Data::Type::check($type_name, -10),    'test type rejects correctly');
is( Kephra::Base::Data::Type::delete($type_name),     1, 'deleted my custom type');
ok( !($type_name ~~ [Kephra::Base::Data::Type::list_names()]), 'new deleted types gets not listed anymore');
ok( !('-' ~~ [Kephra::Base::Data::Type::list_shortcuts()]), 'deleted types shortcut gets not listed anymore');
is( Kephra::Base::Data::Type::resolve_shortcut('-'), '', 'deleted shotcut can not be resolved');
is( Kephra::Base::Data::Type::is_known($type_name),   0, 'test type not present again');
is( Kephra::Base::Data::Type::is_known($type_name),   0, 'test type not present again');
is( add($type_name, 'just for this test',sub{-5 < $_[0] and $_[0] < 5}, 12, 'int'), 0, 'default value of type has to be of type');


is( add($type_name => {default => 2, help => 'just for this test',
                       check => sub{-5 < $_[0] and $_[0] < 5}, parent => 'int',
                       shortcut => '-'}),             1, 'HASHref syntax for add type');
ok( ($type_name ~~ [Kephra::Base::Data::Type::list_names()]), 'again created type gets listed');
ok( ('-' ~~ [Kephra::Base::Data::Type::list_shortcuts()]), 'again created type shortcut gets listed');
is( Kephra::Base::Data::Type::resolve_shortcut('-'), $type_name, 'shortcut of type can be resolved');
is( Kephra::Base::Data::Type::is_known($type_name),   1, 'HASHref test type is present now');
is( Kephra::Base::Data::Type::is_owned($type_name),   1, 'HASHref test type is recognized as own my current package');
is( Kephra::Base::Data::Type::get_default_value($type_name), 2, 'HASHref type got default value of self made type');
is( Kephra::Base::Data::Type::check($type_name,   1),'', 'HASHref test type accepts correctly');
ok( Kephra::Base::Data::Type::check($type_name, -10),    'HASHref test type rejects correctly');
is( Kephra::Base::Data::Type::delete($type_name),     1, 'deleted HASHref custom type');


my $child = 'three';
is( Kephra::Base::Data::Type::delete('num'),          0, 'can not delete default types');
is( Kephra::Base::Data::Type::delete($type_name),     0, 'can not delete none existing types');
add($type_name, 'fiverr',sub{-5 < $_[0] and $_[0] < 5}, 0,'int');
is( Kephra::Base::Data::Type::is_known($type_name),   1, 'test type is present again');
add($child, 'test child type',sub{$_[0] ==3}, 3, $type_name);
is( Kephra::Base::Data::Type::is_known($child),    1, 'child test type is present');
is( Kephra::Base::Data::Type::check($child,   3), '', 'child test type accepts correctly');
ok( Kephra::Base::Data::Type::check($child,   2),     'child test type rejects correctly');
is( Kephra::Base::Data::Type::delete($type_name),  1, 'deleted my custom type');
is( Kephra::Base::Data::Type::is_known($child),    1, 'child test type is still present');
is( Kephra::Base::Data::Type::check($child,   3), '', 'child test type still accepts correctly');
ok( Kephra::Base::Data::Type::check($child,   2),     'child test type still rejects correctly');
add($type_name, 'fiverr',sub{-5 < $_[0] and $_[0] < 5}, 0,'int');


my $cb = Kephra::Base::Data::Type::get_callback('int');
my $cb2 = Kephra::Base::Data::Type::get_callback('int');
ok( ref $cb eq 'CODE',                    'got a real callback');
ok( $cb eq $cb2,                          'got a same callback twice');
is( $cb->(5),                         '', 'recognize integer by callback');
is( $cb->(-12),                       '', 'recognize negative integer by callback');
is( $cb->(1_2e12),                    '', 'recognize huge integer by callback');
ok( $cb->(1.5),                           'real is not an integer by callback');
ok( $cb->('das'),                         'string is not an integer, found by callback');
ok( $cb->({}),                            'hash ref is not an integer, found by callback');


sub add { Kephra::Base::Data::Type::add(@_) }

package Typest;
use Test::More;

is( Kephra::Base::Data::Type::delete($type_name), 0, 'can not deleted what I did not create');
is( Kephra::Base::Data::Type::is_known($type_name), 1, 'test type is still nown');

exit 0;

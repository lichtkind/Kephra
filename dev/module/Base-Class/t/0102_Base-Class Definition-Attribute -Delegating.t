#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 22;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
require Kephra::Base::Class::Definition::Attribute::Delegating;
my $class = 'Kephra::Base::Class::Definition::Attribute::Delegating';
my $req_properies = {name => 'name', help => 'help', class => 'K::B::C', delegate => 'method'};


my $def = Kephra::Base::Class::Definition::Attribute::Delegating->new($req_properies);
is( ref $def,                                 $class,        'created first delegating attribute definition object');

ok( not (ref Kephra::Base::Class::Definition->new()),        'need a name to create class definition');
ok( not (ref Kephra::Base::Class::Definition->new('a')),     'need a ucfirst name to create class definition');
is( $def->is_complete,                             0,        'a new clas definition is not complete');
is( $def->get_method('blub'),                  undef,        'can not get definition of unknown method');
is( $def->get_attribute('platsch'),            undef,        'can not get definition of unknown attribute');
is( $def->get_type('bubu'),                    undef,        'can not get definition of unknown type');
is( $def->attribute_names(),                   undef,        'no attribute definitions to list');
is( $def->method_names(),                          2,        'only two default method definitions to list');
is( $def->get_dependencies(),                  undef,        'now class definition has no dependencies');
is( $def->get_requirements(),                  undef,        'now class definition has no requirements');


exit 0;

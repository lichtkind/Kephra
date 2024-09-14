#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 83;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
require Kephra::Base::Class::Definition::Method;

sub mk_method_def {Kephra::Base::Class::Definition::Method->new(@_)}
my $class = 'Kephra::Base::Class::Definition::Method';



exit 0;

__END__
use Kephra::Base::Class::Definition;    my $class = 'Kephra::Base::Class::Definition';

my $def = Kephra::Base::Class::Definition->new('C');
is( ref $def,                                 $class,        'created class definition object');
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


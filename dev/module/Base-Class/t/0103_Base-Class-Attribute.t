#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 42;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Scope qw/cat_scope_path/;
use Kephra::Base::Class::Attribute;

is( Kephra::Base::Class::Attribute::is_known(), 0, 'undef is not ref to known attribute');
is( Kephra::Base::Class::Attribute::get(),      0, 'can not call get on undef attribute ref');
is( Kephra::Base::Class::Attribute::set(),      0, 'can not call set on undef attribute ref');
is( Kephra::Base::Class::Attribute::delete(),   0, 'can not delete attribute ref that is already undef');

my $var = 0;
my $fake_attr = bless \$var, 'Kephra::Base::Class::Attribute'; # authentic attributes can only be created by the package
is( Kephra::Base::Class::Attribute::is_known($fake_attr), 0, 'fake (unregistered) attribute is not known');
is( Kephra::Base::Class::Attribute::get($fake_attr),      0, 'fake attribute has no getter');
is( Kephra::Base::Class::Attribute::set($fake_attr),      0, 'fake attribute has no setter');
is( Kephra::Base::Class::Attribute::delete($fake_attr),   0, 'fake attribute can not be deleted');

my $real_attr = Kephra::Base::Class::Attribute::create();
ok (not($real_attr), '0 is not enough arguments to create attribute');
$real_attr = Kephra::Base::Class::Attribute::create('class', 'attr');
ok (not($real_attr), 'class and name are enough arguments to create attribute');
my $attr_types = Kephra::Base::Class::Attribute::Type->new();
my $scope = cat_scope_path('attribute', 'class', 'attr');
$real_attr = Kephra::Base::Class::Attribute::create('class', 'attr', $attr_types);
ok (not($real_attr), 'class, name and types are enough arguments to create attribute');
$real_attr = Kephra::Base::Class::Attribute::create('class', 'attr', $attr_types, 'int');
is( ref $real_attr, $scope, 'finally enough arguments to create attribute');

is( $real_attr->get(),   0, 'attribute has correct default value (getter works)');
is( $real_attr->set(2),  2, 'setter of created attribute works');
is( $real_attr->get(),   2, 'value provided by set, has been stored');
is( $real_attr->reset(), 0, 'resetter works');
is( $real_attr->get(),   0, 'resetter has restored value of attribute correctly');
$real_attr->set(2);
is( $real_attr->set(1.1), undef, 'type checks of stter work');
ok( $$real_attr, 'got error message becasue failed type checks');

# add getter and setter getsetter
$real_attr->set(2);
my $subscope = 'Sub::Class';
my $aself = bless \$var, $subscope;
is( Kephra::Base::Class::Attribute::add_getter('attr', $real_attr, $subscope.'::geta', $aself ), 1, 'mounted a getter via add_getter');
is( $aself->geta(), 2, 'mounted a getter works');
is( Kephra::Base::Class::Attribute::add_setter('attr', $real_attr, $subscope.'::seta', $aself ), 1, 'mounted a setter via add_getter');
is( $aself->seta(3), 3, 'mounted a setter via add_getter');
is( $aself->geta(), 3, 'mounted setter works, stored value');
is( $aself->seta(1.1), undef, 'type check of mounted setter works');
ok( $$aself, 'got error message becasue failed type checks');
is( Kephra::Base::Class::Attribute::add_getsetter('attr', $real_attr, $subscope.'::gseta', $aself ), 1, 'mounted a getter/setter via add_getter');
is( $aself->gseta(), 3, 'mounted a getter /setter via add_getsetter');
is( $aself->gseta(4), 4, 'mounted getter/setter works as setter');
is( $aself->gseta(), 4, 'mounted getter/setter works as getter');
is( $aself->gseta(1.1), undef, 'type check of mounted getter/setter works');
ok( $$aself, 'got error message becasue failed type checks');

$real_attr->set(2);
is( Kephra::Base::Class::Attribute::is_known($real_attr), 1, 'real attribute is known');
is( Kephra::Base::Class::Attribute::get($real_attr),      2, 'outward getter works');
is( Kephra::Base::Class::Attribute::set($real_attr, 3),   3, 'outward setter works');
is( Kephra::Base::Class::Attribute::get($real_attr),      3, 'outward setter stored value');
is( Kephra::Base::Class::Attribute::delete($real_attr, $aself), 3, 'attribute deleted');
is( Kephra::Base::Class::Attribute::is_known($real_attr), 0, 'real attribute has been deleted');

is( $aself->geta(), undef, 'mounted a getter no longer works on deleted attribute');
is( $aself->seta(4), undef, 'mounted a setter no longer works on deleted attribute');
is( $aself->gseta(), undef, 'mounted a getter/setter no longer works as getter on deleted attribute');
is( $aself->gseta(4), undef, 'mounted a getter/setter no longer works as setter on deleted attribute');


exit 0;

#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 34;

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
is( ref $real_attr, cat_scope_path('attribute', 'class', 'attr'), 'finally enough arguments to create attribute');



#is( Kephra::Base::Class::Attribute::is_known(''), 0, 'random string does not refer to a known attribute');
#is( Kephra::Base::Class::Attribute::get(''),      0, 'can not get attribute on string');
#is( Kephra::Base::Class::Attribute::set(''),      0, 'can not set attribute on string');
#is( Kephra::Base::Class::Attribute::delete(''),   0, 'can not delete attribute on string');

#is( Kephra::Base::Class::Attribute::is_known({}), 0, 'random ref is not known attribute');
#is( Kephra::Base::Class::Attribute::get({}),      0, 'can not get attribute on random ref');
#is( Kephra::Base::Class::Attribute::set({}),      0, 'can not set attribute on random ref');
#is( Kephra::Base::Class::Attribute::delete({}),   0, 'can not delete attribute on random ref');

my $class  = 'class';
my $value  = 'value';
my $attr_ref = Kephra::Base::Class::Attribute::create($class, $value);


#is( Kephra::Base::Class::Attribute::create(1,2,3),                     0, 'can not create attribute with too much args');
#ok( ref $attr_ref,                                                        'can create attribute with enough args');
#is( ref $attr_ref, 'Kephra::Base::Class::Attribute',                      'attribute has right class');
#is( $$attr_ref,                                                           $class, 'attribute ref has right content');
#is( Kephra::Base::Class::Attribute::is_known($attr_ref),             1, 'newly created attribute is known');
#is( Kephra::Base::Class::Attribute::get($attr_ref),             $value, 'get attribute value');
#is( Kephra::Base::Class::Attribute::set($attr_ref, 2),               2, 'set attribute value');
#is( Kephra::Base::Class::Attribute::delete($attr_ref),               2, 'delete attribute');
#is( Kephra::Base::Class::Attribute::is_known($attr_ref),             0, 'deleted attribute is not known');
#is( Kephra::Base::Class::Attribute::get($attr_ref),                  0, 'can not get deleted attribute');
#is( Kephra::Base::Class::Attribute::set($attr_ref, 2),               0, 'can not set deleted attribute');
#is( Kephra::Base::Class::Attribute::delete($attr_ref),               0, 'can not delete a deleted attribute');


my $attr_ref2 = Kephra::Base::Class::Attribute::create($class, $value);
#isnt( $attr_ref, $attr_ref2,           'next attribute gets different reference');
#is ( $attr_ref2->is_known(),        1, 'attr is known (OO interface)');
#is ( $attr_ref2->get(),       'value', 'getter works (OO interface)');
#is ( $attr_ref2->set('val'),    'val', 'setter works (OO interface)');
#is ( $attr_ref2->get(),         'val', 'set value was stored (OO interface)');
#is ( $attr_ref2->delete(),      'val', 'delete works (OO interface)');
#is ( $attr_ref2->is_known(),        0, 'deleted attr is not known (OO interface)');
#is ( $attr_ref2->get(),             0, 'do not get unknown attribute (OO interface)');
#is ( $attr_ref2->set(2),            0, 'can not set unknown attribute (OO interface)');
#is ( $attr_ref2->delete(),          0, 'can not delete unknown attribute (OO interface)');

exit 0;

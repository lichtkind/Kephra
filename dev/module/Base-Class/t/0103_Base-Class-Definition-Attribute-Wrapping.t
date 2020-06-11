#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 40;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
require Kephra::Base::Class::Definition::Attribute::Wrapping;
my $class = 'Kephra::Base::Class::Definition::Attribute::Wrapping';
sub mk_attr_def {Kephra::Base::Class::Definition::Attribute::Wrapping->new(@_)}
my $req_properies = {name => 'name', help => 'help', class => 'Splitter', wrap => 'method'};

my $def = mk_attr_def( {%$req_properies, build => 'code' } );
is( ref $def,                                               $class,        'created wrapping attribute definition object');
is( $def->get_kind,                                     'wrapping',        'check getter of "kind" property');
is( $def->get_help,                                         'help',        'check getter of "help" property');
is( $def->get_type,                                          undef,        'check getter of "type" property');
is( $def->get_init,                                          undef,        'check getter of "init" property');
is( $def->get_build,                                        'code',        'check getter of "build" property');
is( $def->is_lazy,                                               0,        'check getter of "lazy" property');
is( $def->accessor_names,                                        1,        'attribute has only one getter');
is( ($def->accessor_names)[0],                            'method',        'got the right wrapper method name');
is( $def->auto_accessors,                                    undef,        'no "auto methods"');
is( $def->get_dependency,                                    undef,        'check getter of "dependency" property');
is( $def->get_requirement,                              'Splitter',        'check getter of "requirement" property');

$def = mk_attr_def( {%$req_properies, build => 'code', require => 'Wx', wrap => [qw/a b/] } );
is( ref $def,                                               $class,        'created wrapping attribute definition with required module');
is( $def->get_requirement,                                    'Wx',        '"require" property overwrites "class" as requirement');
is( $def->accessor_names,                                        2,        'attribute has only one getter');
is( ($def->accessor_names)[0],                                 'a',        'got the first wrapper method name right');
is( ($def->accessor_names)[1],                                 'b',        'got the second wrapper method name right');

$def = mk_attr_def( {%$req_properies, lazy_build => 'code' } );
is( ref $def,                                               $class,        'created wrapping attribute definition with lazy constructor');
is( $def->get_build,                                        'code',        'getting the "code" sources');
is( $def->get_init,                                          undef,        'check getter of "init" property');
is( $def->is_lazy,                                               1,        'this property is lazily constructed');

ok(not (ref mk_attr_def([])),                                              'new needs an hash ref to create delegating attribute definition');
ok(not (ref mk_attr_def({name => 'name', help => 'help', class => 'class', wrap => 'd' })),      'build code is missing');
ok(not (ref mk_attr_def({name => 'name', help => 'help', class => 'class', build => 'code'})),   'wrapper method is missing');
ok(not (ref mk_attr_def({name => 'name', help => 'help', wrap => 'd', build => 'code', require=>1})), 'class name is missing');
ok(not (ref mk_attr_def({name => 'name', class => 'class', wrap => 'd', build => 'code'})),      'help text is missing');
ok(not (ref mk_attr_def({help => 'help', class => 'class', wrap => 'd', build => 'code'})),      'attribute name is missing');

ok(not (ref mk_attr_def({%$req_properies, init => 'a', build => 'code'})), 'added unspecced propery');
ok(not (ref mk_attr_def({%$req_properies, lazy_build => 'a', build => 'code'})), 'only one build code allowed');
ok(not (ref mk_attr_def({%$req_properies, build => []})),                        'build code has to be string');
ok(not (ref mk_attr_def({%$req_properies, lazy_build => qr//})),                 'also lazy build code has to be string');
ok(not (ref mk_attr_def({%$req_properies, build => '', wrap => {}})),            'wrapper are in ARRAY or string');
ok(not (ref mk_attr_def({%$req_properies, name => [], build => ''})),            'attribute "name" can not be a reference');
ok(not (ref mk_attr_def({%$req_properies, name => '', build => ''})),            'attribute "name" can not be a empty');
ok(not (ref mk_attr_def({%$req_properies, help => [], build => ''})),            'attribute "help" string can not be a reference');
ok(not (ref mk_attr_def({%$req_properies, help => '', build => ''})),            'attribute "help" string can not be a empty');
ok(not (ref mk_attr_def({%$req_properies, class => [], build => ''})),           'attribute "class" can not be a reference');
ok(not (ref mk_attr_def({%$req_properies, class => '', build => ''})),           'attribute "class" can not be a empty');
ok(not (ref mk_attr_def({%$req_properies, require => [], build => ''})),         'property "require" can not be a reference');
ok(not (ref mk_attr_def({%$req_properies, require => '', build => ''})),         'property "require" can not be a empty');
exit 0;

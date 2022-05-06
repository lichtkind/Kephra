#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/switch/;
use Test::More tests => 37;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
require Kephra::Base::Class::Definition::Attribute;

sub mk_attr_def {Kephra::Base::Class::Definition::Attribute::Raw->new(@_)}
my $class = 'Kephra::Base::Class::Definition::Attribute::Raw';
my $req_properies = {name => 'name', help => 'help', type => 'int'};

my $def = mk_attr_def({%$req_properies});

is( ref $def,                                               $class,        'created first data attribute definition object with minimal properties');
is( $def->kind,                                              'raw',        '"kind" property has set value');
is( $def->help,                                             'help',        '"help" property has set value');
is( $def->type,                                              'int',        '"type" property has set value');
is( $def->build_code,                                           '',        '"build" property has defailt value');
is( $def->is_lazy,                                               0,        '"lazy" property has default value');
is( $def->getter_name,                                      'name',        '"getter_name" property has default value');
is( $def->getter_scope,                                   'access',        '"getter_scope" property has default value');
is( $def->setter_name,                                      'name',        '"setter_name" property has default value');
is( $def->setter_scope,                                    'build',        '"setter_scope" property has default value');


$def = mk_attr_def({type => 'name', help => 'help'});
like( $def,                              qr/lacks 'name' property/,        "property 'name' is missing");
$def = mk_attr_def({name => 'name', type => 'help'});
like( $def,                              qr/lacks 'help' property/,        "property 'help' is missing");
$def = mk_attr_def({name => 'name', help => 'help'});
like( $def,                              qr/lacks 'type' property/,        "property 'type' is missing");


$def = mk_attr_def({%$req_properies, getter => 'get'});
like( $def,                                      qr/unknown scope/,        'tried to put getter into unknown scope');
$def = mk_attr_def({%$req_properies, getter => 'private'});
is( ref $def,                                               $class,        'attribute definition with getter scope set to private');
is( $def->getter_name,                                      'name',        '"getter_name" property - has default value');
is( $def->getter_scope,                                  'private',        '"getter_scope" property - has set value');
$def = mk_attr_def({%$req_properies, getter => {'new_name' => 'blub'}});
like( $def,                                      qr/unknown scope/,        'tried to put newly named getter into unknown scope');
$def = mk_attr_def({%$req_properies, getter => {'new_name' => 'public', b => 'private'}});
like( $def,                                     qr/ too many keys/,        'too complex getter definition');
$def = mk_attr_def({%$req_properies, getter => {'new_name' => 'private'}});
is( $def->getter_name,                                  'new_name',        '"getter_name" property - has set value');
is( $def->getter_scope,                                  'private',        '"getter_scope" property - has set value');

$def = mk_attr_def({%$req_properies, setter => 'set'});
like( $def,                                      qr/unknown scope/,        'tried to put setter into unknown scope');
$def = mk_attr_def({%$req_properies, setter => 'public'});
is( ref $def,                                               $class,        'attribute definition with setter scope set to private');
is( $def->setter_name,                                      'name',        '"setter_name" property - has default value');
is( $def->setter_scope,                                   'public',        '"setter_scope" property - has set value');
$def = mk_attr_def({%$req_properies, setter => {'new_name' => 'blub'}});
like( $def,                                      qr/unknown scope/,        'tried to put newly named setter into unknown scope');
$def = mk_attr_def({%$req_properies, setter => {'new_name' => 'public', b => 'private'}});
like( $def,                                     qr/ too many keys/,        'too complex setter definition');
$def = mk_attr_def({%$req_properies, setter => {'new_name' => 'access'}});
is( $def->setter_name,                                  'new_name',        '"setter_name" property - has set value');
is( $def->setter_scope,                                   'access',        '"setter_scope" property - has set value');


$def = mk_attr_def({%$req_properies, build => 'build'});
is( ref $def,                                               $class,        'could change build code');
is( $def->build_code,                                      'build',        '"build" property has set value');
is( $def->is_lazy,                                               0,        '"lazy" property has default value');
$def = mk_attr_def({%$req_properies, lazy_build => 'lazy_build'});
is( ref $def,                                               $class,        'could change lazy build code ');
is( $def->build_code,                                 'lazy_build',        '"build" property has set value');
is( $def->is_lazy,                                               1,        '"lazy" property has set value');
$def = mk_attr_def({%$req_properies, build => 'build', lazy_build => 'lazy_build'});
is( $def->build_code,                                 'lazy_build',        '"build" property overwritten by "lazy_build"');
is( $def->is_lazy,                                               1,        '"lazy" property has set value');



exit 0;

__END__

t: 0102_Base-Class-Definition-Attribute-Raw.t
 
attribute name => {help => '',                            # help = long name/description for help messages
                   type => 'name',                        # normal data type or class type, whis is not a class itself
       ?         getter => 'scope',                       # method setter_name gets access to attribute
       ?|        getter => {name => scope};               # autogenerated getter name
       ?         setter => 'scope',                       # method setter_name gets access to attribute
       ?|        setter => {name => scope};               # autogenerated getter name
       ?|  [lazy_]build => 'code'                         # code to build default value (optionally lazy) (none lazy can also be done in constructor)

required 
  help :  ~      min length 10
  type :  ~      -e
  name :  ~

optional
    getter : ~ // name
    setter : ~ // name
 get_scope : 'build' | 'access' | 'private' | 'public' // 'access'
 set_scope : 'build' | 'access' | 'private' | 'public' // 'build'
   is_lazy : ? // 0
     build : ~(code) // ''             # create default value (reset)
#!/usr/bin/perl -w
use v5.20;
use warnings;
use Test::More tests => 83;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
require Kephra::Base::Class::Definition::Attribute;

sub mk_attr_def {Kephra::Base::Class::Definition::Attribute->new(@_)}
my $class = 'Kephra::Base::Class::Definition::Attribute';


like( mk_attr_def(),                         qr/need two argumens/,        "all params missing");
like( mk_attr_def({}),                       qr/need two argumens/,        "missing name parameter");
like( mk_attr_def('name', []),            qr/has to be a HASH ref/,        "wrong ref type");
like( mk_attr_def('name', '...'),         qr/has to be a HASH ref/,        "definition ha to be a HASH ref");
is( not(ref mk_attr_def('name', {})),                            1,        "missing essential properties (like help)");

my $def = mk_attr_def('name', { type => 'int'});
like( $def,                           qr/needs a descriptive text/,        "property 'help' is missing");
$def = mk_attr_def('name', {help => 'int', type => 'int'});
like( $def,                           qr/descriptive text of more/,        'help too short');
$def = mk_attr_def('name', {help => 'help...............'});
like( $def,                             qr/misses under key 'type'/,       "property 'type' is missing");

$def = mk_attr_def( 'name', {help => 'long text ...', type => 'int'});
is( ref $def,                                               $class,        'help long enough');
is( $def->kind,                                           'native',        '"kind" property has default value');
is( $def->help,                                    'long text ...',        '"help" property has set value');
is( $def->type,                                              'int',        '"type" property has set value');
is( $def->build_code,                                           '',        '"build" property has default value');
is( $def->is_lazy,                                               0,        '"lazy" property has default value');
is( $def->getter_name,                                      'name',        '"getter_name" property has default value');
is( $def->getter_scope,                                   'access',        '"getter_scope" property has default value');
is( $def->setter_name,                                      'name',        '"setter_name" property has default value');
is( $def->setter_scope,                                    'build',        '"setter_scope" property has default value');

$def = mk_attr_def( 'name', {help => 'long text ...', type => 'int', kind => 'native'});
is( ref $def,                                               $class,        'declare attr explicitly as native');
is( $def->kind,                                           'native',        '"kind" property has default value');
is( $def->help,                                    'long text ...',        '"help" property has set value');
is( $def->type,                                              'int',        '"type" property has set value');
is( $def->build_code,                                           '',        '"build" property has default value');
is( $def->is_lazy,                                               0,        '"lazy" property has default value');
is( $def->getter_name,                                      'name',        '"getter_name" property has default value');
is( $def->getter_scope,                                   'access',        '"getter_scope" property has default value');
is( $def->setter_name,                                      'name',        '"setter_name" property has default value');
is( $def->setter_scope,                                    'build',        '"setter_scope" property has default value');

my $req_properies = {help => 'long text ...', type => 'int'};
$def = mk_attr_def('name', {%$req_properies, getter => 'get'});
like( $def,                                      qr/unknown scope/,        'tried to put getter into unknown scope');
$def = mk_attr_def('name', {%$req_properies, getter => []});
like( $def,                           qr/ has to be a name string/,        'getter can not be array ref');
$def = mk_attr_def('name', {%$req_properies, getter => 'private'});
is( ref $def,                                               $class,        'attribute definition with getter scope set to private');
is( $def->getter_name,                                      'name',        '"getter_name" property - has default value');
is( $def->getter_scope,                                  'private',        '"getter_scope" property - has set value');
$def = mk_attr_def('name', {%$req_properies, getter => {'new_name' => 'blub'}});
like( $def,                                      qr/unknown scope/,        'tried to put newly named getter into unknown scope');
$def = mk_attr_def('name', {%$req_properies, getter => {'new_name' => 'public', b => 'private'}});
like( $def,                                     qr/ too many keys/,        'too complex getter definition');
$def = mk_attr_def('name', {%$req_properies, getter => {'new_name' => 'private'}});
is( $def->getter_name,                                  'new_name',        '"getter_name" property - has set value');
is( $def->getter_scope,                                  'private',        '"getter_scope" property - has set value');
is( $def->kind,                                           'native',        '"kind" property has default value');

$def = mk_attr_def('name', {%$req_properies, setter => 'set'});
like( $def,                                      qr/unknown scope/,        'tried to put setter into unknown scope');
$def = mk_attr_def('name', {%$req_properies, setter => []});
like( $def,                           qr/ has to be a name string/,        'setter can not be array ref');
$def = mk_attr_def('name', {%$req_properies, setter => 'public'});
is( ref $def,                                               $class,        'attribute definition with setter scope set to private');
is( $def->setter_name,                                      'name',        '"setter_name" property - has default value');
is( $def->setter_scope,                                   'public',        '"setter_scope" property - has set value');
$def = mk_attr_def('name', {%$req_properies, setter => {'new_name' => 'blub'}});
like( $def,                                      qr/unknown scope/,        'tried to put newly named setter into unknown scope');
$def = mk_attr_def('name', {%$req_properies, setter => {'new_name' => 'public', b => 'private'}});
like( $def,                                     qr/ too many keys/,        'too complex setter definition');
$def = mk_attr_def('name', {%$req_properies, setter => {'new_name' => 'access'}});
is( $def->setter_name,                                  'new_name',        '"setter_name" property - has set value');
is( $def->setter_scope,                                   'access',        '"setter_scope" property - has set value');
is( $def->kind,                                           'native',        '"kind" property has default value');

$def = mk_attr_def('name', {%$req_properies, build => 'build'});
is( ref $def,                                               $class,        'could change build code');
is( $def->build_code,                                      'build',        '"build" property has set value');
is( $def->is_lazy,                                               0,        '"lazy" property has default value');
is( $def->kind,                                           'native',        '"kind" property has default value');
$def = mk_attr_def('name', {%$req_properies, build_lazy => 'lazy_build'});
is( ref $def,                                               $class,        'could change lazy build code ');
is( $def->build_code,                                 'lazy_build',        '"build" property has set value');
is( $def->is_lazy,                                               1,        '"lazy" property has set value');
is( $def->kind,                                           'native',        '"kind" property has default value');
$def = mk_attr_def('name', {%$req_properies, build => 'build', build_lazy => 'lazy_build'});
is( $def->build_code,                                 'lazy_build',        '"build" property overwritten by "build_lazy"');
is( $def->is_lazy,                                               1,        '"lazy" property has set value');

$def = mk_attr_def('name', {%$req_properies, quark => 'build'});
like( $def,                           qr/contains not needed keys/,       'catch unknown attribute keys');

$def = mk_attr_def( 'name', {help => 'long text ...', type => 'int', class => 'msg', kind => 'delegating'});
like( $def,                           qr/contains not needed keys/,       'delegating attr dont have types');
$def = mk_attr_def( 'name', {help => 'long text ...', type => 'int', kind => 'wrapping', require => 'Wx', build => '-'});
like( $def,                           qr/contains not needed keys/,       'wrapping attr too');
$def = mk_attr_def( 'name', {help => 'long text ...', setter => 'int', class => 'msg', kind => 'delegating'});
like( $def,                           qr/contains not needed keys/,       'delegating attr dont have setters');
$def = mk_attr_def( 'name', {help => 'long text ...', setter => 'int', kind => 'wrapping', require => 'Wx', build => '-'});
like( $def,                           qr/contains not needed keys/,       'wrapping attr too');


$req_properies = {help => 'long text ...', kind => 'delegating', class => 'class', build => 'build'};
$def = mk_attr_def( 'name', $req_properies);
is( ref $def,                                               $class,        'created delegating attr def');
is( $def->kind,                                       'delegating',        '"kind" property has default value');
is( $def->help,                                    'long text ...',        '"help" property has set value');
is( $def->class,                                           'class',        '"type" property has set value');
is( $def->build_code,                                      'build',        '"build" property has set value');
is( $def->is_lazy,                                               0,        '"lazy" property has set value');
is( $def->getter_name,                                      'name',        '"getter_name" property has default value');
is( $def->getter_scope,                                   'access',        '"getter_scope" property has default value');
is( $def->setter_name,                                          '',        '"setter_name" property has default value');
is( $def->setter_scope,                                         '',        '"setter_scope" property has default value');


$req_properies = {help => 'long text ...', kind => 'wrapping', require => 'class', build_lazy => 'lazy_build', getter => { g => 'public'}};
$def = mk_attr_def( 'name', $req_properies);
is( ref $def,                                               $class,        'created wrapping attr def');
is( $def->kind,                                         'wrapping',        '"kind" property has default value');
is( $def->help,                                    'long text ...',        '"help" property has set value');
is( $def->class,                                           'class',        '"type" property has set value');
is( $def->build_code,                                 'lazy_build',        '"build" property has set value');
is( $def->is_lazy,                                               1,        '"lazy" property has set value');
is( $def->getter_name,                                         'g',        '"getter_name" property has set value');
is( $def->getter_scope,                                   'public',        '"getter_scope" property has set value');
is( $def->setter_name,                                          '',        '"setter_name" property has default value');
is( $def->setter_scope,                                         '',        '"setter_scope" property has default value');

exit 0;

__END__

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
 getter_scope : 'build' | 'access' | 'private' | 'public' // 'access'
 setter_scope : 'build' | 'access' | 'private' | 'public' // 'build'
      is_lazy : ? // 0
        build : ~(code) // ''             # create default value (reset)

delegating attribute  name  => {help => '',                # help = long name/description for help messages
                      class => 'Kephra::...',              # class of attribute (has to be a KBOS class)
       ?|            getter => 'scope',                    # method setter_name gets access to attribute
       ?|            getter => {name => scope};            # autogenerated getter name
       ?| [lazy_]build_args => ['code']|{a=>'cod'}# eval to build args values

required 
   help :  ~      min length 10
  class :  ~      -e
   name :  ~

optional
  getter_name : ~ // name
 getter_scope : 'build' | 'access' | 'private' | 'public' // 'access'
      is_lazy : ? // 0
        build : ~(code) // ''             # create default value (reset)

empty 
  setter_name : ~ // name
 setter_scope : 'build' | 'access' | 'private' | 'public' // 'build'

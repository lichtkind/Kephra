use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Attribute;
our $VERSION = 0.5;

use Kephra::Base::Data::Type;
use Kephra::Base::Class::Definition::Attribute::Data;
use Kephra::Base::Class::Definition::Attribute::Delegating;
use Kephra::Base::Class::Definition::Attribute::Wrapping;

sub new {        # ~pkg ~name %properties       --> ._| ~errormsg
    my ($pkg, $name, $attr_def_data) = (@_);
    return "attribute definition needs an identifier (a-z,a-z0-9_) as first argument" if Kephra::Base::Data::Type::standard->check_type('identifier', $name);
    my ($error_start, $type_def) = ("attribute $name");
    return "$error_start got no property hash to define itself" unless ref $attr_def_data eq 'HASH';
    return "$error_start needs a descriptive 'help' text of more than 5 character" unless exists $attr_def_data->{'help'} and length $attr_def_data->{'help'} > 5;
    $attr_def_data->{'name'} = $name;
    if    (exists $attr_def->{'get'})      {Kephra::Base::Class::Definition::Attribute::Data->new($attr_def_data)}
    elsif (exists $attr_def->{'delegate'}) {Kephra::Base::Class::Definition::Attribute::Delegating->new($attr_def_data)}
    elsif (exists $attr_def->{'wrap'})     {Kephra::Base::Class::Definition::Attribute::Wrapping->new($attr_def_data)}
    else {return "definition of attribute $name lacks accessor name in get, delegate or wrap property (one only!)"}
}

1;
__DATA__

attribute name => {help => '',                           # help = long name/description for help messages
                   type => 'name',                       # normal data type or class type, whis is not a class itself
                   get  => setter_name|[setter_name,..], # method setter_name gets access to attribute # -name = autogenerated getter/setter name
         ?         set  => getter_name|[getter_name,..]; # method getter_name gets access to attribute # -name = autogenerated getter/setter name
         ?  init[_lazy] => $val                          # initial value when its different from the type ones
         ? build[_lazy] => 'code'                        # code to build default value (optionally lazy) (none lazy can also be done in constructor)

delegating attribute name  => {help => '',                # help = long name/description for help messages
                              class => 'Kephra::...',     # class of attribute (has to be a KBOS class)
                           delegate => { -dname => 'orig'}# auto generate method 'self->dname' which maps to 'attr->orig'
                                      |[-dname,..]|dname  # without renames
                 ?      init[_lazy] => []|{},             # args to construct attribute object (positional [] or named {}, first is method name)

wrapping attribute name => { help  => '',                 # short explaining text for better ~errormsg
                            class  => 'Kephra::...',      # class of attribute (can be any)
                           require => 'Module'            # 1 if require class
                            wrap   => [wrapper_name,]     # claim this to be implemented wrapper method as belonging to this attribute
                      build[_lazy] => ['code']|{name=>''} # code snippets to run (lazily) create $attr object


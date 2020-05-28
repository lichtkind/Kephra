use v5.16;
use warnings;

package Kephra::Base::Class::Syntax;

use Kephra::Base::Class::Builder;

sub import    {} # establish new keywords
sub unimport  {} # remove them

1;

__END__

class C;                                                 # starts a class definition, 

type name => {help => 'description what is checked', 
              code => '...', 
              default => val,
            ? parent => type_name,                       # help, code and default can be inherited from parent
            ? parameter => 'name' | { name => '',        # just to create parametric type
                                    ? parent => '',      # overwerite name of parameter type
                                    ? default => ..},    # overwrite default value of parameter type


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
                 ?     build[_lazy] => ['code']|{name=>''}# code snippets to run (lazily) to eval $args

wrapping attribute name => { help  => '',                 # short explaining text for better ~errormsg
                            class  => 'Kephra::...',      # class of attribute (can be any)
                           require => 'Module'            # 1 if require class
                            wrap   => [wrapper_name,]     # claim this to be implemented wrapper method as belonging to this attribute
                 ?    build[_lazy] => ['code']|{name=>''} # code snippets to run (lazily) create $attr object


# if no method is marked as constructor and destructor, new and demolish will be autogenerated,
# and if new or demolish already exists and is not constructor/destructor, class definition can not be completed

constructor new     (sig) {@_ = $self, $args, $attr};     # build method is called by new             # $self has only here access to getter and setter in build scope
destructor demolish (sig) {@_ = $self, $args, $attr};     # canonical name for destructor method     # called autmatically or by hand                  # build scope

[public/private](g|s)etter [method] name (sig) {($self, $args, $attr->name/help/get/set/reset) = @_};                          # scope determined by attr def
[public/private] delegator [method] name (sig) {$self, $args, $attr->name/help/get/class) = @_}
[public/private] wrapper [method] name (sig) {$self, $args, $attr->name/help/get/class) = @_}

[public] [multi] method name (sig) {$self, $args) = @_}   # methods are per default public, every multi has to be named multi
 private [multi] method name (sig) {$self, $args) = @_}   # private methods are only callable inside the class
                                                          # multi can be public, private, accessor - all of the multis has to be marked as such 

                             (sig) = (type argname, ~arg, array of str arg, @~arg, index of attr list arg - i of arg l argname  --> type, @~ )
                                     #  required parameter                                                 optional parameter       return types
                                     #                                                                                       no --> if nothing should be returned


ACCESS RULES: 

see:              any obj ref     inside any       g/setter     constructor
                  everywhere   method of class   deleg./wrap.  deconstructor
public method
and accessors          *              *               *              *
in public scope

private method or                     *               *              *
private g/s

access scope g/s                                      *              *

build scope  g/s                                                     *


#argument name => {help => 'description', 
#                  type => 'name', 
#           ? attribute => 'name'};                      # argument is relative to what attribute

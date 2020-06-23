use v5.20;
use warnings;

package Kephra::Base::Class::Syntax;

use Kephra::Base::Class::Syntax::Signature;
use Kephra::Base::Class::Syntax::Parser;
use Kephra::Base::Class::Builder;

sub import    {} # establish new keywords
sub unimport  {} # remove them

1;

__END__

class C;                                                  # starts a class definition, 

type name => {help => 'description what is checked', 
              code => '...', 
              default => val,
            ? parent => type_name,                        # help, code and default can be inherited from parent
            ? parameter => 'name' | { name => '',         # just to create parametric type
                                    ? parent => '',       # overwerite name of parameter type
                                    ? default => ..},     # overwrite default value of parameter type



attribute name => {help => '',                            # help = long name/description for help messages
                   type => 'name',                        # normal data type or class type, whis is not a class itself
         |         get  => getter_name|[getter_name,..],  # method setter_name gets access to attribute
         |    auto_get  => {name => scope};               # autogenerated getter name
       ?           set  => setter_name|[setter_name,..];  # method setter_name gets access to attribute 
       ?      auto_set  => {name => scope};               # autogenerated setter name
       ?|   [lazy_]init => $val                           # initial value when its different from the type ones
       ?|  [lazy_]build => 'code'                         # code to build default value (optionally lazy) (none lazy can also be done in constructor)

delegating attribute name  => {help => '',                # help = long name/description for help messages
                              class => 'Kephra::...',     # class of attribute (has to be a KBOS class)
                 |         delegate => del_name|[name,..];# delegator method that get access to the attribute
                 |    auto_delegate => {dname => 'scope'} # auto generate method 'self->dname' which maps to 'attr->dname'
                                       {dname => { to => 'orig', scope => 'public'}} # auto generate method 'self->dname' which maps to 'attr->orig', default scope is access
                  ?       auto_get  => {name => scope};   # autogenerated getter name
               ?|       [lazy_]init => [$val]|{attr=>$val}# args to construct attribute object (positional [] or named {}, first is method name)
               ?|      [lazy_]built => ['code']|{a=>'cod'}# eval to build args values

wrapping attribute name => { help  => '',                 # short explaining text for better ~errormsg
                            class  => 'Kephra::...',      # class of attribute (can be any)
                ?          require => 'Module'            # 1 if require class
                             wrap  => [wrapper_name]|name # claim this to be implemented wrapper method as belonging to this attribute
                 |    [lazy_]built => 'code'              # code snippets to run (lazily) create $attr object and bring it into init state




# if no method is marked as constructor and destructor, 'new' and 'demolish' will be autogenerated,
# and if 'new' or 'demolish' already exists and they are no constructor/destructor, the class can not be created
# constructor/destructor are implicitly public

constructor new     (sig) {@_ = $self, $args, $attr};     # build method is called by new             # $self has only here access to getter and setter in build scope
destructor demolish (sig) {@_ = $self, $args, $attr};     # canonical name for destructor method     # called autmatically or by hand                  # build scope

[public/private](g|s)etter [method] name (sig) {($self, $args, $attr->name/help/get/set/reset) = @_};   # default scope is access
[public/private] delegator [method] name (sig) {($self, $args, $attr->name/help/get/class) = @_}
[public/private] wrapper   [method] name (sig) {($self, $args, $attr->name/help/get/class) = @_}

 public  [multi] method name (sig) {$self, $args) = @_}   # methods are per default private, every multi has to be named multi
[private][multi] method name (sig) {$self, $args) = @_}   # private methods are only callable inside the class
                                                          # multi can be public, private, accessor - all of the multis has to be marked as such 

                             (sig) = (type argname, ~arg, array of str arg, @~arg, index of attr list arg - i of arg l argname  --> type, @~ - opt)
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

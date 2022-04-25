use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.7;
use Kephra::Base::Data;
use Kephra::Base::Class::Definition::Attribute;
use Kephra::Base::Class::Definition::Method;
use Kephra::Base::Class::Definition::Scope;

sub new               {}  # ~class_name                                      --> ._|~errormsg
sub restate           {}  # %state                                           --> ._|~errormsg
sub state             {}  # ._                                               --> %state

sub get_attribute     {}  # ._  ~attribute_name                              --> %attr_def|undef
sub get_method        {}  # ._  ~method_name                                 --> %method_def|undef
sub get_type          {}  # ._                                               --> .type

sub get_dependencies  {}  # ._                                               --> @~attr_def.~class    # KBOS classes
sub get_requirements  {}  # ._                                               --> @~attr_def.~class    # packages
sub is_complete       {}  # ._                                               --> ?

sub complete          {}  # ._                                               --> ~errormsg

sub add_type          {}  # ._  ~type_name %type_def                         --> ~errormsg
sub add_attribute     {}  # ._  ~name %properties                            --> ~errormsg
sub add_method        {}  # ._  ~name @signature ~code %keywords             --> ~errormsg

sub attribute_names   {}  # ._  - ~kind                                      --> @~attr_def.~name    # ~kind = 'data'|'deleg...'|'wrap...'
sub method_names      {}  # ._  - ~kind ~scope ?multi                        --> @~method_def.~name  # ~kind = ''|'simple'|'getter'|'setter'|'accessor'|'wrapper'|'delegator'|'constructor'
                                                                                                     # ~scope = 'public'|'private'|'access'
1;                                                                                                   # ~multi = 'multi'|'only'| default = all

__END__


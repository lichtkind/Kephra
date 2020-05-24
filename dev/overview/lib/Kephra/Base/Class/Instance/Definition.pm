use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.3;
use Kephra::Base::Data::Type;

sub new               {}  # ~class_name                                      --> ._|~errormsg
sub restate           {}  # %state                                           --> ._|~errormsg
sub state             {}  # ._                                               --> %state

sub complete          {}  # ._                                               --> ~errormsg
sub is_complete       {}  # ._                                               --> ?
sub get_dependencies  {}  # ._                                               --> @~name

sub add_type          {}  # ._  ~type_name %type_def                         --> ~errormsg
sub add_attribute     {}  # ._  ~name %properties                            --> ~errormsg
sub add_method        {}  # ._  ~name @signature ~code %keywords             --> ~errormsg

sub get_types         {}  # ._                                               --> .type_store
sub get_attribute     {}  # ._  ~attribute_name                              --> %attr_def|undef
sub get_method        {}  # ._  ~method_name                                 --> %method_def|undef

sub attribute_names   {}  # ._  - ~kind                                      --> @~name    # ~kind = 'data'|'deleg...'|'wrap...'
sub method_names      {}  # ._  - ~kind ~scope ?multi                        --> @~name    # ~kind = ''|'simple'|'getter'|'setter'|'accessor'|'wrapper'|'delegator'|'constructor'
                                                                                           # ~scope = 'public'|'private'|'access'
1;                                                                                         # ~multi = 'multi'|'only'| default = all

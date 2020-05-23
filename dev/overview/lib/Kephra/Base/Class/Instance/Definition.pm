use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.1;
use Kephra::Base::Data::Type;

sub new               {}  # ~name                       --> ._|~errormsg
sub restate           {}  # %state                      --> ._
sub state             {}  # ._                          --> %state

sub complete          {}  # ._                          --> ~errormsg
sub is_complete       {}  # ._                          --> ?
sub get_dependencies  {}  # ._                          --> @~name

sub add_type          {}  # ._  ~name %properties       --> ~errormsg
sub add_attribute     {}  # ._  ~name %properties       --> ~errormsg
sub add_method        {}  # ._  ~name %properties       --> ~errormsg

sub get_types         {}  # .cdef                       --> .type_store
sub get_attribute     {}  # .cdef                       --> %attr_def
sub get_method        {}  # .cdef                       --> %method_def

sub attribute_names   {}  # .cdef - ~kind               --> @~name    # ~kind = 'data'|'deleg...'|'wrap...'
sub method_names      {}  # .cdef - ~kind ~scope ?multi --> @~name    # ~kind = ''|'simple'|'getter'|'setter'|'accessor'|'wrapper'|'delegator'|'constructor'
                                                                      # ~scope = 'public'|'private'|'access'
1;                                                                    # ~multi = 'multi'|'only'| default = all

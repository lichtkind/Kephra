use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.1;

sub new              {}     # ~name                     --> .cdef
sub restate          {}     # %state                    --> .cdef
sub state            {}     # .cdef                     --> %state

sub complete         {}     # .cdef                     --> ~errormsg
sub is_complete      {}     # .cdef                     --> ?
sub get_dependencies {}     # .cdef                     --> @~name

sub add_type         {}     # .cdef ~name %properties   --> ~errormsg
sub add_argument     {}     # .cdef ~name %properties   --> ~errormsg
sub add_attribute    {}     # .cdef ~name %properties   --> ~errormsg
sub add_method       {}     # .cdef ~name %properties   --> ~errormsg

sub get_types               {}  # .cdef                 --> @%type_def
sub get_arguments           {}  # .cdef                 --> @%arg_def
sub get_data_attributes     {}  # .cdef                 --> @%attr_def
sub get_wrap_attributes     {}  # .cdef                 --> @%attr_def
sub get_deleg_attributes    {}  # .cdef                 --> @%attr_def
sub get_simple_methods      {}  # .cdef                 --> @%method_def
sub get_multi_methods       {}  # .cdef                 --> @%method_def
sub get_accessor_methods    {}  # .cdef                 --> @%method_def
sub get_constructor_methods {}  # .cdef                 --> @%method_def

1;

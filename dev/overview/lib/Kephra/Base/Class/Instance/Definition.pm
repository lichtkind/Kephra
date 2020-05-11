use v5.20;
use warnings;

package Kephra::Base::Class::Definition;


sub new            {}       # ~name                     --> .cdef

sub complete       {}       # .cdef                     --> ~errormsg
sub is_complete    {}       # .cdef                     --> ?

sub add_type       {}       # .cdef ~name %properties   --> ~errormsg
sub add_argument   {}       # .cdef ~name %properties   --> ~errormsg
sub add_attribute  {}       # .cdef ~name %properties   --> ~errormsg
sub add_method     {}       # .cdef ~name %properties   --> ~errormsg


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

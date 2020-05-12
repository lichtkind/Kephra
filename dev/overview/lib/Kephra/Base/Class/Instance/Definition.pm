use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.1;
use Kephra::Base::Data::Type;

sub new               {}  # ~name                       --> .cdef|~errormsg
sub restate           {}  # %state                      --> .cdef
sub state             {}  # .cdef                       --> %state

sub complete          {}  # .cdef                       --> ~errormsg
sub is_complete       {}  # .cdef                       --> ?
sub get_dependencies  {}  # .cdef                       --> @~name

sub add_type          {}  # .cdef ~name %properties     --> ~errormsg
sub add_argument      {}  # .cdef ~name %properties     --> ~errormsg
sub add_attribute     {}  # .cdef ~name %properties     --> ~errormsg
sub add_method        {}  # .cdef ~name %properties     --> ~errormsg

sub get_type          {}  # .cdef                       --> .type
sub get_argument      {}  # .cdef                       --> %arg_def
sub get_attribute     {}  # .cdef                       --> %attr_def
sub get_method        {}  # .cdef                       --> %method_def

sub list_types        {}  # .cdef - ~kind ~ptname       --> @~name    # ~kind = ''='simple'|'param...', ~ptname = param type
sub list_arguments    {}  # .cdef                       --> @~name
sub list_attributes   {}  # .cdef - ~kind               --> @~name    # ~kind = 'data'|'deleg...'|'wrap...'
sub list_methods      {}  # .cdef - ~kind ~scope ?multi --> @~name    # ~kind = ''|'simple'|'getter'|'setter'|'accessor'|'wrapper'|'delegator'|'constructor'
                                                                      # ~scope = 'public'|'private'|'access'|'build'
1;

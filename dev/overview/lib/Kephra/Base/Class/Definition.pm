use v5.20;
use warnings;

package Kephra::Base::Class::Definition;


sub new_class   {} # ~name                     --> ~errormsg

sub complete    {} # .cdef                     --> ?
sub is_complete {} # .cdef                     --> ?
sub is_known    {} # .cdef                     --> ?




sub add_data_attribute       {}    # .cdef ~name %properties --> ~error
sub add_delegating_attribute {}    # .cdef ~name %properties --> ~error
sub add_wrapping_attribute   {}    # .cdef ~name %properties --> ~error

sub add_method               {}    # .cdef ~name %sig ~code ~scope
sub add_type                 {}    # .cdef ~name %properties



sub resolve_dependencies {}    #                            --> ~errror




sub get_types          {} # ~class                     --> \Kephra::Base::Class::Types
sub get_attributes     {} # ~class                     --> %attr_type

sub add_attribute {}      # ~class, ~attr, ~type --> ?
sub get_attribute_type {} # ~class, ~attr        --> ~type



1;

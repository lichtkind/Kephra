use v5.20;
use warnings;

package Kephra::Base::Class::Definition;


sub new         {} # ~name                     --> .cdef

sub complete    {} # .cdef                     --> ~errormsg
sub is_complete {} # .cdef                     --> ?


sub add_type                 {}    # .cdef ~name %properties          --> ~errormsg
sub add_argument             {}    # .cdef ~name %properties          --> ~errormsg
sub add_attribute            {}    # .cdef ~name %properties          --> ~errormsg
sub add_method               {}    # .cdef ~name %sig ~code ~scope




sub get_types          {} # ~class                     --> \Kephra::Base::Class::Types
sub get_attributes     {} # ~class                     --> %attr_type

sub add_attribute {}      # ~class, ~attr, ~type --> ?
sub get_attribute_type {} # ~class, ~attr        --> ~type



1;

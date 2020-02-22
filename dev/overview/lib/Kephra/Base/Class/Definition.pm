use v5.20;
use warnings;

package Kephra::Base::Class::Definition;


sub new_class   {} # ~class                     --> ~error

sub complete    {} # ~class                     --> ?
sub is_complete {} # ~class                     --> ?
sub is_known    {} # ~class                     --> ?




sub add_simple_attribute {}    # ~class, ~name, %properties --> ~error
sub add_delegating_attribute {}# ~class, ~name, %properties --> ~error
sub add_wrapping_attribute {}  # ~class, ~name, %properties --> ~error


sub resolve_dependencies {}    #                            --> ~errror




sub get_types          {} # ~class                     --> \Kephra::Base::Class::Types
sub get_attributes     {} # ~class                     --> %attr_type

sub add_attribute {}      # ~class, ~attr, ~type --> ?
sub add_method    {}      # ~class
sub get_attribute_type {} # ~class, ~attr        --> ~type



1;

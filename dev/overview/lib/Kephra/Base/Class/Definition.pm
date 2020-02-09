use v5.16;
use warnings;

package Kephra::Base::Class::Definition;


sub new_class {}               # ~class                              --> ~error

sub add_simple_attribute {}    # str class, str name, HASH properties --> ~error
sub add_delegating_attribute {}# str class, str name, HASH properties --> ~error
sub add_wrapping_attribute {}  # str class, str name, HASH properties --> ~error


sub resolve_dependencies {}   #      --> str errror



sub create      {} # str class                     --> bool

sub get_types   {} # str class                     --> Kephra::Base::Class::Types

sub add_attribute {}      # str class, str attr, str type --> bool
sub add_method    {}      # str class
sub get_attribute_type {} # str class, str attr           --> str type
sub get_attributes     {} # str class                     --> % attr_type


sub complete    {} # str class                     --> bool
sub is_complete {} # str class                     --> bool
sub is_known    {} # str class                     --> bool


1;

use v5.18;
use warnings;

# central store for namespace constants

package Kephra::Base::Class::Scope;

sub is_name            {}  # ~scope          --> bool
sub method_scope_names {}  #                 --> @~scope
sub all_scope_names    {}  #                 --> @~scope

sub is_first_tighter{}  # ~scopeA ~scopeB    --> bool

sub included_names  {}  # ~scope ~class - ~name ~method  --> @~full_name
sub construct_path  {}  # ~scope ~class - ~name ~method  --> ~full_name

1;

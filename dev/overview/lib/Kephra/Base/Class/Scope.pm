use v5.16;
use warnings;

# central store for namespace constants

package Kephra::Base::Class::Scope;

sub is   {}  # ~scope                      --> bool
sub list {}  #                             --> @~scope
sub list_all {}#                           --> @~scope

sub is_first_tighter{}  # ~scopeA ~scopeB  --> bool

sub included_names  {}  # ~scope ~class - ~name ~method  --> @~full_name
sub name            {}  # ~scope ~class - ~name ~method  --> ~full_name

1;

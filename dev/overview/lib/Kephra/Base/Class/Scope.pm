use v5.20;
use warnings;

# method namespace name constants and their priority logic
# Classname::methodname
# Classname::PRIVATE::methodname
# Classname::ACCESS::methodname
# Classname::BUILD::methodname
# Classname::HOOK::methodname::BEFORE/AFTER
# Classname::ARGUMENT::methodname::argname
# Classname::ATTRIBUTE::attrname::get/set/reset

package Kephra::Base::Class::Scope;

sub method_scopes      {}  #                       --> @~scope
sub all_scopes         {}  #                       --> @~scope

sub is_method_scope    {}  # ~scope                --> ?
sub is_scope           {}  # ~scope                --> ?
sub is_name            {}  # ~SCOPE                --> ?

sub is_first_tighter   {}  # ~scopeA ~scopeB       --> ?

sub included_names     {}  # ~scope ~class - ~name ~method  --> @~full_name
sub cat_scope_path     {}  # ~scope ~class - ~name ~method  --> ~full_name

1;

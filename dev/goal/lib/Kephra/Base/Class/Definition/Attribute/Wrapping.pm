use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Attribute::Wrapping;

our $VERSION = 1.1;

sub new     {}         # ~pkg %attr_def           --> ._ | ~errormsg
sub state   {}         # $_                       --> %state
sub restate {}         # ~pkg %state              --> ._

sub get_kind  {}       # ._    --> 'data'
sub get_help  {}       # ._    --> ~help
sub get_class       {} # ._    --> ~class
sub get_build {}       # ._    --> ~code|undef
sub is_lazy   {}       # ._    --> ?
sub accessor_names  {} # ._    --> @~method_name
sub auto_accessors  {} # ._    --> %def = {name => get_scope | [get_scope, set_scope]}

1;

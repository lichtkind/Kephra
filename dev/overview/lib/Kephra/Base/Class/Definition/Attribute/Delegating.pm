use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Attribute::Delegating;
our $VERSION = 1.2;

sub new     {}         # ~pkg %attr_def           --> ._ | ~errormsg
sub state   {}         # $_                       --> %state
sub restate {}         # ~pkg %state              --> ._

sub get_kind  {}       # ._    --> 'data'
sub get_help  {}       # ._    --> ~help
sub get_class {}       # ._    --> ~class
sub get_default_args{} # ._    --> $val|undef
sub get_build_args {}  # ._    --> ~code|undef
sub is_lazy   {}       # ._    --> ?
sub accessor_names  {} # ._    --> @~method_name
sub auto_accessors  {} # ._    --> %def = { accessor_name => { delegate_to => method &| scope => 'scope' &| get => 'scope'} }

1;

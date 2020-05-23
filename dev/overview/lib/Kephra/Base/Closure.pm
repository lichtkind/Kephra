use v5.20;
use warnings;

package  Kephra::Base::Closure;
our $VERSION = 1.1;
use Kephra::Base::Data;

sub new        {} # ~code - $state .basic_type |~basic_type --> ._|~errormsg   # create call object with own source and state
sub clone      {} # ._                                      --> ._             # create call object with same source and types and same (or different) state
sub restate    {} # %state                                  --> ._|~errormsg   # create call object from state
sub state      {} # ._                                      --> %state         # dump complete internal state of object (all attr) {state => .., source => ..}

sub get_code   {} # ._                        --> ~code
sub get_type   {} # ._                        --> .basic_type         # ~~ .Kephra::Base::Data::Type::Basic
sub get_state  {} # ._                        --> $state              # get $state if $state is of ~get_type
sub set_state  {} # ._ $data                  --> $state|~errormsg    # change $state if $data is of ~set_type, error from .type.checker

sub run        {} # ._ - @arg                 --> $retval             # run evaled source

1;

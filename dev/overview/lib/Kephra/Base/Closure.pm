use v5.20;
use warnings;

package  Kephra::Base::Closure;
our $VERSION = 1.0;
use Kephra::Base::Data::Type;

sub new        {} # ~code - $state .type|~type             --> .closure|~errormsg   # create call object with own source and state
sub clone      {} # .closure                               --> .closure          # create call object with same source and types and same (or different) state
sub restate    {} # %state                                 --> .closure|~errormsg   # create call object from state
sub state      {} # .closure                               --> %state            # dump complete internal state of object (all attr) {state => .., source => ..}

sub get_code   {} # .closure                --> ~code
sub get_type   {} # .closure                --> .type              # ~~ .Kephra::Base::Data::Type::Simple
sub get_state  {} # .closure                --> $state             # get $state if $state is of ~get_type
sub set_state  {} # .closure $data          --> $state|~errormsg   # change $state if $data is of ~set_type, error from .type.checker

sub run        {} # .closure - @arg         --> $retval            # run evaled source

1;

use v5.20;
use warnings;

package  Kephra::Base::Call;
our $VERSION = 0.7;
use Kephra::Base::Data;

sub new        {} # ~code - $state .type|~type                               --> .call|~errormsg   # create call object with own source and state
sub clone      {} # .call                                                    --> .call             # create call object with same source and types and same (or different) state
sub restate    {} # %state                                                   --> .call|~errormsg   # create call object from state
sub state      {} # .call                                                    --> %state            # dump complete internal state of object (all attr) {state => .., source => ..}

sub get_code   {} # .call                   --> ~code
sub get_type   {} # .call                   --> .type              # ~~ .Kephra::Base::Data::Type::Simple
sub get_state  {} # .call                   --> $state             # get $state if $state is of ~get_type
sub set_state  {} # .call $data             --> $state|~errormsg   # change $state if $data is of ~set_type, error from .type.checker

sub run        {} # .call   - @arg          --> $retval            # run evaled source

1;

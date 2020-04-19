use v5.20;
use warnings;

package  Kephra::Base::Call;

sub new        {} # ~source - $state ~set_type ~get_type --> .call|~evalerror|~error   # create call object with own source and state
sub clone      {} # .call                                --> .call                     # create call object with same source and types and same (or different) state
sub restate    {} # %state                               --> .call|~evalerror|~error   # create call object from state
sub state      {} # .call                                --> %state                    # dump complete internal state of object (all attr) {state => .., source => ..}

sub get_source {} # .call                   --> ~source
sub get_gettype{} # .call                   --> ~set_type    # ~~ Kephra::Base::Data::Type checks value on set state
sub get_settype{} # .call                   --> ~get_type    # ~~ Kephra::Base::Data::Type checks value on get state
sub get_state  {} # .call                   --> $state       # get $state if $state is of ~get_type
sub set_state  {} # .call $data             --> $state       # change $state if $data is of ~set_type

sub run        {} # .call   - @arg          --> $retval      # run evaled source

1;

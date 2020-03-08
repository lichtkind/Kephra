use v5.20;
use warnings;

package  Kephra::Base::Call;

sub new        {} # ~source - $state ~set_type ~get_type --> .call|~evalerror|~error   # create call object with own source and state
sub clone      {} # .call                                --> .call                     # create call object with same source and types and same (or different) state

sub get_source {} # .call             --> ~source
sub get_gettype{} # .call             --> ~set_type    # ~~ Kephra::Base::Data::Type 
sub get_settype{} # .call             --> ~get_type    # ~~ Kephra::Base::Data::Type
sub get_state  {} # .call             --> $state       # get $state if $state is of ~get_type
sub set_state  {} # .call $data       --> $state       # change $state if $data is of ~set_type

sub run        {} # .call   - @arg    --> $retval      # run evaled source

1;

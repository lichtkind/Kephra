use v5.20;
use warnings;

package  Kephra::Base::Call;

sub new        {} # ~source - $state  --> .call|~evalerror   # call with own source and state
                  # .call   - $state  --> .call              # another call with same source
sub clone      {} # .call             --> .call              # another call in same source and same state

sub get_source {} # .call             --> ~source
sub get_state  {} # .call             --> $state
sub set_state  {} # .call $data       --> $state

sub run        {} #         : @arg    --> $retval

1;

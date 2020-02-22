use v5.20;
use warnings;

package  Kephra::Base::Call;

sub new        {} # ~source : $data   --> .call|~evalerror
                  # .call   : $data   --> .call
sub clone      {} # .call             --> .call

sub get_source {} #                   --> ~source
sub get_data   {} #                   --> $data
sub set_data   {} # $data             --> $data 

sub run        {} #         : @arg    --> $retval

1;

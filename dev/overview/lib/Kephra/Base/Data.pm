use v5.14;
use warnings;

package Kephra::Base::Data;
use Kephra::Base::Data::Type;

sub clone      {} #  $data  --> $data            # only one parameter
sub clone_list {} #  @data  --> @data

sub date_time      {}

1;

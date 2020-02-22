use v5.14;
use warnings;

package Kephra::Base::Data;
use Kephra::Base::Data::Type::Relative;

sub clone_item {} #  $data  --> $data            # only one parameter
sub clone_list {} #  @data  --> @data

1;

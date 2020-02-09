use v5.16;
use warnings;

package Kephra::Base::Class::Method::Argument;

# create parameter objects and store their values

sub set_methods {} # pkg method parameter --> bool
sub create      {} # pkg method values    --> $param     # parameter object
sub delete      {} # $param               --> val_hash|undef
sub get_all     {} # $param               --> val_hash
sub get_value   {} # $param key           --> val|undef

1;

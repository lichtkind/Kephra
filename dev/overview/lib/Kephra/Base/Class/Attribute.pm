use v5.16;
use warnings;

package Kephra::Base::Class::Attribute;
our $VERSION = 0.03;


sub create         {} # ~key ~value            --> $attr
sub delete         {} # $attr                  --> value
sub is_known       {} # $attr                  --> bool
sub get            {} # $attr                  --> value
sub set            {} # $attr value            --> value

1;

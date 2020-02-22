use v5.20;
use warnings;

package Kephra::Base::Class::Attribute;
our $VERSION = 0.05;
use Kephra::Base::Package;
use Kephra::Base::Class::Scope;
use Kephra::Base::Class::Attribute::Type;

sub create         {} # ~class ~attribute $class_types ~type --> $attr
sub add_getter     {} # $attr ~path $self                    --> bool
sub add_setter     {} # $attr ~path $self                    --> bool
sub add_getsetter  {} # $attr ~path $self                    --> bool
sub delete         {} # $attr                                --> value

sub is_known       {} # $attr                  --> bool
sub get            {} # $attr                  --> value
sub set            {} # $attr value            --> value|0

1;

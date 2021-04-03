use v5.20;
use warnings;

package Kephra::Base::Class::Instance::Argument;
our $VERSION = 0.05;
use Kephra::Base::Package;
use Kephra::Base::Class::Scope;
use Kephra::Base::Data;

sub create         {} # ~class ~attribute .class_types ~type --> .attr
sub delete         {}
sub get_all        {}
sub get_value      {}
sub set_methods    {}
1;


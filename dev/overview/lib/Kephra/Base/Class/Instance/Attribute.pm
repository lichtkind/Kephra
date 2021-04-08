use v5.20;
use warnings;

package Kephra::Base::Class::Instance::Attribute;
our $VERSION = 0.05;
use Kephra::Base::Package;
use Kephra::Base::Class::Definition::Scope;
use Kephra::Base::Data;


sub create         {} # ~class ~attribute .class_types ~type --> .attr
sub add_getter     {} # .attr  ~path  .self                  --> ?
sub add_setter     {} # .attr  ~path  .self                  --> ?
sub add_getsetter  {} # .attr  ~path  .self                  --> ?
sub delete         {} # .attr                                --> $value

sub is_known       {} # .attr                  --> ?
sub get            {} # .attr                  --> $value
sub set            {} # .attr $value           --> $value|0

1;

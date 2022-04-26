use v5.18;
use warnings;

package Kephra::Base::Class::Instance;

use Kephra::Base::Class::Instance::Argument;
use Kephra::Base::Class::Instance::Attribute;

our $VERSION = 0.00;

sub create {}
sub delete {}

sub get_by_ref        {}
sub get_public_self   {}
sub get_private_self  {}
sub get_access_self   {}
sub get_attribute     {}

3;

use v5.20;
use warnings;

# central storage for all classes and their instances

package Kephra::Base::Class::Registry;
our $VERSION = 0.00;


my %object = (); # register of all objects by class name
my %by_ref = (); # cross ref
my %parent = (); # ref to parent object

################################################################################

################################################################################
1;

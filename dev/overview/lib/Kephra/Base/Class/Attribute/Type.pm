use v5.16;
use warnings;

package Kephra::Base::Class::Attribute::Type;
use Kephra::Base::Data::Type;

                         # type means type name
sub add               {} # ~type %def -->  bool         %def : parent @check default help?
sub delete            {} # ~type      -->  bool
sub list_names        {} #            -->  @~type

sub is_known          {} # ~type                -->  bool
sub is_standard       {} # ~type                -->  bool
sub is_owned          {} # ~type ~package ~file -->  bool
sub get_default_value {} # ~type                -->  .val|undef
sub get_callback      {} # ~type                -->  &callback

sub check             {} # ~type .val   -->  errormsg|''    # contains value and what test failed

1;

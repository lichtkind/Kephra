use v5.20;
use warnings;

package Kephra::Base::Class::Attribute::Type;
use Kephra::Base::Data::Type;

sub add               {} # ~type %def           -->  ?         %def - parent @check default help?
sub delete            {} # ~type                -->  ?
sub list_names        {} #                      -->  @~type

sub is_known          {} # ~type                -->  ?
sub is_standard       {} # ~type                -->  ?
sub is_owned          {} # ~type ~package ~file -->  ?
sub get_default_value {} # ~type                -->  $val|undef
sub get_callback      {} # ~type                -->  &callback

sub check             {} # ~type $val $attr     -->  ''|errormsg    # contains value and what test failed

1;

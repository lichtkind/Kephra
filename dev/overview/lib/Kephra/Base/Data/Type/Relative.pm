use v5.20;
use warnings;

# self made data types with checkers that take more arguments
# example = index => {msg => 'in range', code =>'$_[0] < @{$_[1]}', 
#                     arguments =>['array', 'ARRAY'], parent => 'int+'}

package Kephra::Base::Data::Type;

 #                                @arguments[] ~~ {~label, ~type - ~var, ~eval}
sub add          {} # ~type ~code @arguments - $default ~parent ~shortcut --> ? 
sub delete       {} # ~type                                               --> ?

sub list_names       {} #                        --> @~type
sub list_shortcuts   {} #                        --> @~shortcut
sub resolve_shortcut {} #  ~shortcut             -->  ~type

sub is_known           {} # ~type                -->  ?      # is a data type
sub is_standard        {} # ~type                -->  ?      # is predefined ?
sub is_owned           {} # ~type ~package ~file -->  ?

sub get_default_value  {} # ~type                -->  $default|undef
sub get_argument_count {} # ~type                -->  +
sub get_argument_type  {} # ~type +index         -->  ~type
sub get_argument_label {} # ~type +index         -->  ~label

sub get_callback       {} # ~type                -->  &callback|~evalerror
sub curry              {} # ~type                -->  &callback|~evalerror

sub check              {} # ~type @val           -->  ~error    = "reason $val"


1;

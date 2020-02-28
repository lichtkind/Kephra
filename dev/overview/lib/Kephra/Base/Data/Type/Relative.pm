use v5.20;
use warnings;

# self made data types with checkers that take more arguments
# example = index => {msg => 'in range', code =>'$_[0] < @{$_[1]}', 
#                     arguments =>['array', 'ARRAY'], parent => 'int+'}

package Kephra::Base::Data::Type;

#                                     {~msg, ~type - ~var, ~eval}
sub add          {} # ~type ~msg ~code @arguments $default ~parent ~shortcut --> ? 
sub delete       {} # ~type                                                  --> ?

sub list_names       {} #                        --> @~type
sub list_shortcuts   {} #                        --> @~shortcut
sub resolve_shortcut {} #  ~shortcut             -->  ~type

sub is_known           {} # ~type                -->  ?
sub is_standard        {} # ~type                -->  ?
sub is_owned           {} # ~type ~package ~file -->  ?

sub get_message        {} # ~type                -->  ~msg|undef
sub get_code           {} # ~type                -->  ~code|undef
sub get_default_value  {} # ~type                -->  $default|undef
sub get_argument_count {} # ~type                -->  +
sub get_argument       {} # ~type                -->  %argument
sub get_callback       {} # ~type                -->  &callback|~evalerror
sub curry              {} # ~type                -->  &callback|~evalerror

sub check              {} # ~type @val           -->  ~error    = "reason $val"


1;
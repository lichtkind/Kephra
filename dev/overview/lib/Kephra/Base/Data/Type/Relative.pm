use v5.20;
use warnings;

# data type checks that take more arguments // relative, meta types
# example - valid index of an actual array
#  index => {code =>'return out of range if $_[0] >= @{$_[1]}', arguments =>[{name => 'array', type => 'ARRAY', default => []},], 
#            help => 'valid index of array', parent => 'int_pos' },

package Kephra::Base::Data::Type::Relative;

use Kephra::Base::Data::Type;

 #                                @arguments[] ~~ {~label, ~type - ~var, ~eval}
sub add          {} # ~type ~code @arguments - $default ~parent ~shortcut --> ? 
sub delete       {} # ~type                                               --> ?

sub list_names       {}   #                      --> @~type
sub list_shortcuts   {}   #                      --> @~shortcut
sub resolve_shortcut {}   #  ~shortcut           -->  ~type
sub resolve_compount {}   #  ~shortcut           -->  ~type

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

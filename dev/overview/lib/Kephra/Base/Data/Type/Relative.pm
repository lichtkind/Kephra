use v5.20;
use warnings;

# data type checks that take more arguments // relative or meta types
# example - valid index of an actual array
#  index => {code =>'return out of range if $_[0] >= @{$_[1]}', arguments =>[{name => 'array', type => 'ARRAY', default => []},], 
#            help => 'valid index of array', parent => 'int_pos' },
# serialize keys: help, code, default, file, package


package Kephra::Base::Data::Type::Relative;
use Kephra::Base::Data::Type;

sub init               {} #                    compile default types
sub state              {} #        --> %state  dump all active types data
sub restate            {} # %state -->         recreate all type checker from data dump

 #                                @arguments[] ~~ {~label, ~type - ~var, ~eval}
sub add                {} # ~type ~code @arguments - $default ~parent ~shortcut --> ~error 
sub delete             {} # ~type                                               --> ~error

sub list_names         {} #                      --> @~type
sub list_shortcuts     {} #                      --> @~shortcut
sub resolve_shortcut   {} #  ~shortcut           -->  ~type
sub resolve_compount   {} #  ~shortcut           -->  ~type

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

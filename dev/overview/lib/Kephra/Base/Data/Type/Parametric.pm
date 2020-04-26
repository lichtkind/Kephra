use v5.20;
use warnings;

# data type depending second value (parameter) // example - valid index of an actual array
# { name => 'index', help => 'valid index of array', code =>'return out of range if $_[0] >= @{$_[1]}', 
#                    parameter =>[{name => 'array', type => 'ARRAY', default => []},],      parent => 'int_pos' },

package Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type;

sub new                {} # ~name ~help ~code - .parent $default --> .type | ~errormsg # optionally as %args # required: .parent | $default
sub restate            {} # %state                               --> .type | ~errormsg
sub state              {} # .type                 --> %state
sub get_name           {} # .type                 --> ~name
sub get_default_value  {} # .type                 --> $default
sub get_check_pairs    {} # .type                 --> @checks   # [help, code, ..]
sub check              {} # .type $val            --> ~errormsg
sub curry              {} # .type $val            --> ~errormsg


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

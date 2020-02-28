use v5.20;
use warnings;

# self made data types, standards + added by any package (owner)
# example = bool  => {check => ['boolean', '$_[0] eq 0 or $_[0] eq 1'],  parent => 'value', default=>0},

package Kephra::Base::Data::Type;

sub add          {} # ~type ~help &check - $default ~parent ~shortcut --> ?
sub delete       {} # ~type                                           --> ?

sub list_names       {} #                        --> @~type
sub list_shortcuts   {} #                        --> @~shortcut
sub resolve_shortcut {} #  ~shortcut             -->  ~type

sub known_type         {} #                                       alias:
sub is_known           {} # ~type                -->  ?
sub is_standard        {} # ~type                -->  ?
sub is_owned           {} # ~type ~package ~file -->  ?

sub get_default_value  {} # ~type                -->  $default|undef
sub get_checks         {} # ~type                -->  @checks  = [[~help, &check]]
sub get_callback       {} # ~type                -->  &callback|~evalerror

sub check_type     {} #                                         alias:
sub check          {} # ~type $val               -->  ~error    = "reason $val"
sub guess_type     {} #                                         alias:
sub guess          {} # $val                     -->  @~type

1;

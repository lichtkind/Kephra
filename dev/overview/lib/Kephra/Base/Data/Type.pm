use v5.20;
use warnings;

# KBOS data types, standards + added by any package (owner)
# example      : bool  => {help=> '0 or 1', code=> '$_[0] eq 0 or $_[0] eq 1', parent=> 'value',  default=>0, shortcut=> '?'}
# compiled to  : bool  => {check => ['not a reference', 'not ref $_[0]'], '0 or 1', '$_[0] eq 0 or $_[0] eq 1'], 
#                          callback => eval{ sub{ return 'not a reference' if not ref $_[0]; ....; 0} } }

package Kephra::Base::Data::Type;

sub init              {} #                    compile default types
sub state             {} #        --> %state  dump all active types data
sub restate           {} # %state -->         recreate all type checker from data dump

sub add               {} # ~type ~help ~check - $default ~parent ~shortcut --> ~error
sub delete            {} # ~type                                           --> ~error

sub list_names        {} #                       --> @~type
sub list_shortcuts    {} #                       --> @~shortcut
sub resolve_shortcut  {} #  ~shortcut            -->  ~type

sub known_type        {} #                                       alias:
sub is_known          {} # ~type                 -->  ?
sub is_standard       {} # ~type                 -->  ?
sub is_owned          {} # ~type ~package ~file  -->  ?

sub get_default_value {} # ~type                 -->  $default|undef
sub get_checks        {} # ~type                 -->  @checks  = [[~help, &check]]
sub get_callback      {} # ~type                 -->  &callback|~evalerror

sub check_type        {} #                                         alias:
sub check             {} # ~type $val               -->  ~error    = "reason $val"
sub guess_type        {} #                                         alias:
sub guess             {} # $val                     -->  @~type

1;

use v5.20;
use warnings;

# KBOS data types, standards + added by any package (owner)
# serialize keys: check, shortcut, default, file, package

package Kephra::Base::Data::Type;
our $VERSION = 0.1;
use Kephra::Base::Data::Type::Simple;
use Kephra::Base::Data::Type::Parametric;

sub init              {} #                    compile default types
sub state             {} #        --> %state  dump all active types data
sub restate           {} # %state -->         recreate all type checker from data dump


sub create_simple     {} # ~name ~help ~code - .parent|~parent  $default     --> .type | ~errormsg
sub create_param      {} # ~name ~help %parameter ~code .parent|~parent - $default --> .ptype | ~errormsg
                         #             %{.type|~type - ~name $default }      

sub add               {} # ~[p]type ~shortcut          --> ~errormsg
sub remove            {} # ~type - ~param              --> ~errormsg
sub get               {} # ~type - ~param ~uni         --> ~errormsg
sub list_names        {} #                             --> @~[p]type
sub list_shortcuts    {} #                             --> @~shortcut
sub resolve_shortcut  {} # ~shortcut - ~param          -->  ~type

sub known_type        {} #                                       alias:
sub is_known          {} # ~[p]type                    -->  ?
sub is_standard       {} # ~[p]type                    -->  ?
sub is_owned          {} # ~[p]type                    -->  ?

sub check_type        {} #                                         alias:
sub check             {} # ~type $val - $param         -->  ~errormsg    = "reason $val"
sub guess_type        {} #                                         alias:
sub guess             {} # $val                        -->  @~type

1;

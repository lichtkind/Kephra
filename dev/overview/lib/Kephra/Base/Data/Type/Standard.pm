use v5.20;
use warnings;

# KBOS store for standard data type checker objects, + added by owners + dep resolver +
#      serialize keys: check, shortcut, default, file, package

package Kephra::Base::Data::Type::Standard;
our $VERSION = 1.3;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;


sub init              {} #                    compile default types
sub state             {} #        --> %state  dump all active types data
sub restate           {} # %state -->         recreate all type checker from data dump


sub create_simple     {} # ~name ~help ~code - .parent|~parent  $default     --> .type | ~errormsg
sub create_param      {} # ~name ~help %parameter ~code .parent|~parent - $default --> .ptype | ~errormsg
                         #             %{.type|~type - ~name $default }      

sub add               {} # ~[p]type ~shortcut          --> ~errormsg
sub remove            {} # ~type - ~param              --> ~errormsg
sub get               {} # ~type - ~param              --> ~errormsg
sub get_shortcut      {} # ~type - ~kind               --> ~errormsg
sub list_names        {} # - ~kind ~name               --> @~type|@~ptype|@~param   # ~kind = 'simple'|'para[meter]'
sub list_shortcuts    {} # - ~kind                            --> @~shortcut
sub resolve_shortcut  {} # ~shortcut - ~param          -->  ~type

sub known_type        {} #                                       alias:
sub is_known          {} # ~[p]type                    -->  ?
sub is_initial        {} # ~[p]type                    -->  ?
sub is_owned          {} # ~[p]type                    -->  ?

sub check_type        {} #                                         alias:
sub check_simple      {} # ~type $val                  -->  ~errormsg            # = "reason $val"
sub check_param       {} # ~type $param $val $pval     -->  ~errormsg    
sub guess_type        {} #                                         alias:
sub guess             {} # $val                        -->  @~type               # guess simple type

1;

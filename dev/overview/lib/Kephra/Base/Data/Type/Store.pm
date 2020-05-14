use v5.20;
use warnings;

# extendable collection of simple and parametric type objects + dependency resolver
# multiple parametric types with same name and different parameters must have same owner and shortcut (basic type shortcuts have own name space)

package Kephra::Base::Data::Type::Store;
our $VERSION = 0.5;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;


sub new               {} # - 'open'   --> .tstore                                     # open store can not finalized
sub state             {} #            --> %state          dump all active types data
sub restate           {} # %state     --> .tstore         recreate all type checker from data dump

sub is_open           {} # .tstore                         --> ?
sub close             {} # .tstore                         --> ?
                         #                                                              .type|%{.type|~type - ~name $default}
                         #         .type |{~name ~help ~code - .parent|~parent $default %parameter}
sub add_type          {} # .tstore .type - ~shortcut       --> ~errormsg
sub add_shortcut      {} # .tstore ~kind ~type ~shortcut   --> ~errormsg
sub remove_type       {} # .tstore ~type - ~param          --> .type|~errormsg
sub remove_shortcut   {} # .tstore ~kind ~shortcut         --> ~errormsg

sub get_type          {} # .tstore ~type - ~param          -->  ~errormsg
sub get_shortcut      {} # .tstore ~type - ~kind           -->  ~errormsg             # ~kind = 'simple'|'para[meter]'
sub resolve_shortcut  {} # .tstore ~shortcut - ~param      -->  ~type
sub list_type_names   {} # .tstore - ~kind ~ptype          --> @~btype|@~ptype|@~param
sub list_shortcuts    {} # .tstore - ~kind                 --> @~shortcut
sub list_forbidden_shortcuts {} # .tstore                  --> @~shortcut
sub forbid_shortcuts  {} # .tstore @~shortcut              --> ?                      # can not forbid forbidden or shortcuts currently in use

sub is_known          {} # .tstore ~type - ~param          --> ?
sub is_owned          {} # .tstore ~type - ~param          --> ?

sub check_basic_type  {} # .tstore ~type $val              -->  ~errormsg             # = "reason $val"
sub check_param_type  {} # .tstore ~type ~param $val $pval -->  ~errormsg    
sub guess_basic_type  {} # .tstore $val                    --> @~type                 # guess simple type

4;

use v5.20;
use warnings;

# extendable collection of simple and parametric type objects + deps resolver
#      serialize type keys: object, shortcut, file, package

package Kephra::Base::Data::Type::Store;
our $VERSION = 0.5;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;

sub new               {} # - 'open'   --> .tstore                                     # open store can not finalized
sub state             {} #            --> %state          dump all active types data
sub restate           {} # %state     --> .tstore         recreate all type checker from data dump

                         #                                                              .type|%{.type|~type - ~name $default}
                         #         .type |{~name ~help ~code - .parent|~parent $default %parameter}
sub add_type          {} # .tstore .type - ~shortcut       --> ~errormsg
sub add_shortcut      {} # .tstore ~kind ~type ~shortcut   --> ~errormsg
sub remove_type       {} # .tstore ~type - ~param          --> .type|~errormsg
sub remove_shortcut   {} # .tstore ~kind ~shortcut         --> ~errormsg
sub is_open           {} # .tstore                         --> ?
sub close             {} # .tstore                         --> ?

sub get_type          {} # .tstore ~type - ~param          -->  ~errormsg
sub get_shortcut      {} # .tstore ~type - ~kind           -->  ~errormsg
sub resolve_shortcut  {} # .tstore ~shortcut - ~param      -->  ~type
sub list_names        {} # .tstore - ~kind ~name           --> @~type|@~ptype|@~param # ~kind = 'simple'|'para[meter]'
sub list_shortcuts    {} # .tstore - ~kind                 --> @~shortcut
sub list_forbidden_shortcuts {} # .tstore                  --> @~shortcut
sub forbid_shortcuts  {} # .tstore @~shortcut              --> ?

sub is_known          {} # .tstore ~type - ~param          --> ?
sub is_owned          {} # .tstore ~type - ~param          --> ?

sub check_basic       {} # .tstore ~type $val              -->  ~errormsg             # = "reason $val"
sub check_param       {} # .tstore ~type ~param $val $pval -->  ~errormsg    
sub guess_basic       {} # .tstore $val                    --> @~type                 # guess simple type

4;

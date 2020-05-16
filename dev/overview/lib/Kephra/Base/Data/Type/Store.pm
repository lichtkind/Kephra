use v5.20;
use warnings;

# extendable collection of simple and parametric type objects + dependency resolver
# multiple parametric types with same name and different parameters must have same owner and shortcut (basic type shortcuts have own name space)

package Kephra::Base::Data::Type::Store;
our $VERSION = 1.0;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;


sub new                   {} # - 'open'                        --> .tstore      open store can not finalized
sub state                 {} #                                 --> %state       dump all active types data
sub restate               {} # %state                          --> .tstore      recreate all type checker from data dump

sub is_open               {} # .tstore                         --> ?
sub close                 {} # .tstore                         --> ?

                             #         .type |{~name ~help ~code - .parent|~parent $default %parameter = ~btype|.btype|%btype_def}
sub add_type              {} # .tstore .type - ~shortcut       --> ~errormsg
sub remove_type           {} # .tstore ~type - ~param          --> .type|~errormsg
sub get_type              {} # .tstore ~type - ~param          --> ~errormsg

sub is_type_known         {} # .tstore ~type - ~param          --> ?
sub is_type_owned         {} # .tstore ~type - ~param          --> ?

sub add_shortcut          {} # .tstore ~kind ~type ~shortcut   --> ~errormsg
sub remove_shortcut       {} # .tstore ~kind ~shortcut         --> ~errormsg
sub get_shortcut          {} # .tstore ~kind ~type             --> ~errormsg    ~kind = 'simple'|'para[meter]'
sub resolve_shortcut      {} # .tstore ~kind ~shortcut         --> ~type

sub list_type_names       {} # .tstore - ~kind ~ptype          --> @~btype|@~ptype|@~param
sub list_shortcuts        {} # .tstore - ~kind                 --> @~shortcut
sub list_forbidden_shortcuts{}#.tstore                         --> @~shortcut
sub forbid_shortcuts      {} # .tstore @~shortcut              --> ~errormsg    can not forbid forbidden or shortcuts currently in use

sub check_basic_type      {} # .tstore ~type $val              -->  ~errormsg   = "reason $val"
sub check_param_type      {} # .tstore ~type ~param $val $pval -->  ~errormsg    
sub guess_basic_type      {} # .tstore $val                    --> @~type       guess simple type

4;

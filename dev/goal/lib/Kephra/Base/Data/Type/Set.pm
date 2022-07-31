use v5.20;
use warnings;

# extendable collection of simple and parametric type objects + dependency resolver
# multiple parametric types with same name and different parameters must have same owner and shortcut (basic type shortcuts have own name space)

package Kephra::Base::Data::Type::Set;
our $VERSION = 1.21;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;


sub new                      {} # - 'open'                           --> ._       open store can not finalized
sub state                    {} # ._                                 --> %state   dump all active types data
sub restate                  {} # %state                             --> ._       recreate all type checker from data dump

sub is_open                  {} # ._                                 --> ?
sub close                    {} # ._                                 --> ?

sub list_type_names          {} # ._  - ~kind ~param_type            --> @~btype|@~ptype|@~param   # ~name     == a-z,(a-z0-9_)*
sub list_shortcuts           {} # ._  - ~kind                        --> @~shortcut                # ~shortcut == [^a-z0-9_]
sub list_forbidden_shortcuts {} # ._                                 --> @~shortcut

sub add_type                 {} # ._  .type|%typedef - ~shortcut     --> ~errormsg
sub remove_type              {} # ._  ~type - ~param                 --> .type|~errormsg
sub get_type                 {} # ._  ~type - ~param                 --> ~errormsg
 
sub is_type_known            {} # ._  ~type - ~param                 --> ?
sub is_type_owned            {} # ._  ~type - ~param                 --> ?

sub add_shortcut             {} # ._  ~kind ~type ~shortcut          --> ~errormsg
sub remove_shortcut          {} # ._  ~kind ~shortcut                --> ~errormsg
sub get_shortcut             {} # ._  ~kind ~type                    --> ~errormsg    ~kind = 'simple'|'para[meter]'
sub resolve_shortcut         {} # ._  ~kind ~shortcut                --> ~type|undef
sub forbid_shortcuts         {} # ._ @~shortcut                      --> ~errormsg    can not forbid forbidden or shortcuts currently in use

sub check_basic_type         {} # ._  ~type $val                     -->  ~errormsg   = "reason $val"
sub check_param_type         {} # ._  ~type ~param $val $pval        -->  ~errormsg    
sub guess_basic_type         {} # ._  $val                           --> @~type       guess simple type

4;

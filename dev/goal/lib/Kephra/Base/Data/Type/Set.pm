use v5.20;
use warnings;

# extendable collection of simple and parametric type objects (2 name spaces) + dependency resolver
# store shortcut symbols correlating to base names independent of parameter type
#  open sets ($self->{open} eq 'open') cannot be closed (like normal == 0 | 1 = ?) 

package Kephra::Base::Data::Type::Set;
our $VERSION = 1.21;
use Kephra::Base::Data::Type::Factory;


sub new                      {} #   -- 'open'                        --> ._       open store can not finalized
sub state                    {} # _                                  --> %state   dump all active types data
sub restate                  {} # %state                             --> ._       recreate all type checker from data dump

sub is_open                  {} # _                                  --> ?
sub close                    {} # _                                  --> ?

sub list_type_names          {} # _  - ~kind ~param_type             --> @~btype|@~ptype|@~param   # ~name     == a-z,(a-z0-9_)*
sub list_shortcuts           {} # _  - ~kind                         --> @~shortcut                # ~shortcut == [^a-z0-9_]
sub list_forbidden_shortcuts {} # _                                  --> @~shortcut

sub add_type                 {} # _ .type|%typedef - ~shortcut       --> ~errormsg
sub remove_type              {} # _ ~type - ~param                   --> .type|~errormsg
sub get_type                 {} # _ ~type - ~param                   --> .type|~errormsg
 
sub is_type_known            {} # _ ~type - ~param                   --> ?
sub is_type_owned            {} # _ ~type - ~param                   --> ?

sub add_shortcut             {} # _ ~kind ~type ~shortcut            --> ~errormsg
sub remove_shortcut          {} # _ ~kind ~shortcut                  --> ~errormsg
sub get_shortcut             {} # _ ~kind ~type                      --> ~shortcut|~errormsg       # ~kind = 'simple'|'para[meter]'
sub resolve_shortcut         {} # _ ~kind ~shortcut                  --> ~full_name|undef
sub allow_shortcuts          {} # _ @~shortcut                       --> @~shortcut                # already allowed shortcuts
sub forbid_shortcuts         {} # _ @~shortcut                       --> @~shortcut                # already forbidden shortcuts

5;

use v5.20;
use warnings;

# extendable collection of simple and parametric type objects (2 name spaces) + dependency resolver
# store shortcut symbols correlating to base names independent of parameter type
#  open sets ($self->{open} eq 'open') cannot be closed (like normal == 0 | 1 = ?) 

package Kephra::Base::Data::Type::Set;
our $VERSION = 0.3;
use Kephra::Base::Data::Type::Factory;


sub new                      {} #   -- 'open'                        --> ._       open store can not finalized
sub state                    {} # _                                  --> %state   dump all active types data
sub restate                  {} # %state                             --> ._       recreate all type checker from data dump

sub is_open                  {} # _                                  --> ?
sub close                    {} # _                                  --> ?


sub add_type                 {} # _ .type|%typedef - ~symbol         --> ~errormsg
sub remove_type              {} # _ ~type - ~param                   --> .type|~errormsg
sub get_type                 {} # _ ~type - ~param                   --> .type|~errormsg
sub list_type_names          {} # _  - ~kind ~param_type             --> @~btype|@~ptype|@~param # ~name     == a-z,(a-z0-9_)*
 
sub is_type_known            {} # _ ~type - ~param                   --> ?
sub is_type_owned            {} # _ ~type - ~param                   --> ?


sub add_symbol               {} # _ ~kind ~type ~symbol              --> ~errormsg
sub remove_symbol            {} # _ ~kind ~symbol                    --> ~errormsg
sub get_symbol               {} # _ ~kind ~type                      --> ~symbol|~errormsg       # ~kind = 'simple'|'para[meter]'
sub resolve_symbol           {} # _ ~kind ~symbol                    --> ~full_name|undef

sub list_symbols             {} # _  - ~kind                         --> @~symbol                # ~shortcut == [^a-z0-9_]
sub list_forbidden_symbols   {} # _                                  --> @~symbol
sub allow_symbols            {} # _ @~symbol                         --> @~symbol                # already allowed shortcuts
sub forbid_symbols           {} # _ @~symbol                         --> @~symbol                # already forbidden shortcuts
sub is_symbol                {} # _ ~symbol                          --> ?

5;

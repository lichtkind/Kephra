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

sub is_open                  {} # _                                  --> ? | 'open'
sub close                    {} # _                                  --> ?


sub add_type                 {} # _ .type|%typedef - ~symbol         --> .type|~!
sub remove_type              {} # _ ~full_name                       --> .type|~!
sub get_type                 {} # _ ~full_name                       --> .type|~!
sub list_type_names          {} # _ - ~kind ~param_name              --> @~btype|@~ptype|@~param # ~name     == a-z,(a-z0-9_)*
 
sub is_type_known            {} # _ ~full_name                       --> ?
sub is_type_owned            {} # _ ~full_name                       --> ?


sub add_symbol               {} # _ ~symbol ~full_name               --> ~!
sub remove_symbol            {} # _ ~symbol ~full_name               --> ~!
sub symbol_from_full_name    {} # _ ~full_name                       --> ~symbol|~!              # ~kind = 'simple'|'para[meter]'
sub full_name_from_symbol    {} # _ ~symbol - ~kind                  --> ?~full_name

sub list_symbols             {} # _ - ~kind                          --> @~symbol                # shortcuts for basic (default) or params
sub list_forbidden_symbols   {} # _                                  --> @~symbol
sub allow_symbols            {} # _ @~symbol                         --> @~symbol                # now allowed shortcuts
sub forbid_symbols           {} # _ @~symbol                         --> @~symbol                # now forbidden shortcuts
                                                                                                 # ~shortcut == [^a-z0-9_]
5;

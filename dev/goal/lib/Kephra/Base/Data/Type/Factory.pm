use v5.20;
use warnings;

# utils for type object creation: checking, deps resolve, ID conversion

package Kephra::Base::Data::Type::Factory;
our $VERSION = 0.2;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;

                                # .T type object (basic | param)
                                # .R resolver object
                                # ~! error msg

sub create_type              {} # $Tdef      --> .T | ~!                 # type def has objects as parent or param
sub create_type_chain        {} # $Tdef      --> - full_name => .T, ..   # type def may have type def as parent or param
                                #              | .T                      # in scalar context
                                #              | .R - .R                 # 1 or 2 resolver objects
sub get_ID_resolver          {} # %Tdef      --> - .R - .R                
sub root_parent_ID           {} # %Tdef      --> - typeID, %Tdef
sub root_parameter_ID        {} # %Tdef      --> - typeID, %Tdef


sub base_name_from_ID        {} # $typeID    --> ~name
sub param_name_from_ID       {} # $typeID    --> ~name
sub full_name_from_ID        {} # $typeID    --> ~full_name 
sub ID_from_full_name        {} # ~full_name --> $typeID
sub full_name_kind           {} # ~full_name --> ( 'basic' | 'param' | '' )

sub is_type_ID               {} # $typeID    --> ?
sub type_ID_kind             {} # $typeID    --> ( 'basic' | 'param' | '' )


sub is_type_def              {} # %Tdef      --> ?
sub is_basic_type_def        {} # %Tdef      --> ?
sub is_param_type_def        {} # %Tdef      --> ?
sub type_def_kind            {} # %Tdef      --> ( 'basic' | 'param' | '' )

 
sub is_type                  {} # .T         --> ?
sub is_basic_type            {} # .T         --> ?
sub is_param_type            {} # .T         --> ?
sub type_kind                {} # .T         --> ( 'basic' | 'param' | '' )

package Kephra::Base::Data::Type::Resolver;

sub new                      {} # $typeID, %Tdef, ('parent'|'parameter')  --> _ | ~!
sub open_ID                  {} # _                                       --> $typeID
sub resolve_open_ID          {} # .T | $Tdef                              --> ?

4;

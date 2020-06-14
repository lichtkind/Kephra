use v5.20;
use warnings;

# helper functions for type creation

package Kephra::Base::Data::Type::Util;
our $VERSION = 1.0;

use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;

our @type_class_names;

sub can_substitude_names   {} # %type_def                              -->  =amount
sub substitude_names       {} # %type_def @.type_store                 -->  =amount
sub create_type            {} # %type_def @.type_store                 -->  .type
sub is_type                {} # .type                                  -->  ?
sub resolve_type_shortcut  {} # ~kind ~shortcut @.type_store           --> ~type

5;

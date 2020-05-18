use v5.20;
use warnings;

# helper functions for type creation

package Kephra::Base::Data::Type::Util;
our $VERSION = 0.7;

use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;


sub can_substitude_names   {} # %type_def                              -->  =amount
sub substitude_names       {} # %type_def @.type_store                 -->  =amount
sub create_type            {} # %type_def @.type_store                 --> .type

5;

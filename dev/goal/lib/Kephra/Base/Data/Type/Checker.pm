use v5.20;
use warnings;

# extendable collection of simple and parametric type objects + dependency resolver
# multiple parametric types with same name and different parameters must have same owner and shortcut (basic type shortcuts have own name space)

package Kephra::Base::Data::Type::Checker;
our $VERSION = 1.21;

use Kephra::Base::Data::Type::Namespace;


1;

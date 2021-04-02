use v5.16;
use warnings;

# parse self made OO syntax and call the builder appropriately
# signature syntax handeled by K::B::Class::Method::Signature

package Kephra::Base::Class::Syntax;
our $VERSION = 0.06;
use Keyword::Simple;
use Kephra::Base::Class::Syntax::Parser;
use Kephra::Base::Class::Syntax::Signature;
use Kephra::Base::Class::Builder;
################################################################################

################################################################################
1;

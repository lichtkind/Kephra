use v5.20;
use warnings;

# definitions of standard data type checker objects

package Kephra::Base::Data::Type::Standard;
our $VERSION = 2.0;
use Kephra::Base::Data::Type::Basic;

our @forbidden_shortcuts;
our %basic_shortcuts;
our %parametric_shortcuts;
our @basic_types;
our @parametric_types;

5;

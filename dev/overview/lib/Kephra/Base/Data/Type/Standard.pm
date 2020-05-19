use v5.20;
use warnings;

# definitions and store of standard data type checker objects

package Kephra::Base::Data::Type::Standard;
our $VERSION = 2.4;
use Kephra::Base::Data::Type::Basic;

our @basic_type_definitions;
our @parametric_type_definitions;
our @forbidden_shortcuts;
our %basic_type_shortcut;
our %parametric_type_shortcut;

sub init_store        {}   #    -->  .tstore
sub store             {}   #    -->  .tstore

6;

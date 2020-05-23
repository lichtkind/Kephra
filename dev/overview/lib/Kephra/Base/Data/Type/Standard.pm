use v5.20;
use warnings;

# definitions and store of standard data type checker objects

package Kephra::Base::Data::Type::Standard;
our $VERSION = 2.5;
use Kephra::Base::Data::Type::Basic;

our @basic_type_definitions;
our @parametric_type_definitions;
our %basic_type_shortcut;
our %parametric_type_shortcut;
our @forbidden_shortcuts;

sub init_store        {}   #    -->  .type_store
sub store             {}   #    -->  .type_store

6;

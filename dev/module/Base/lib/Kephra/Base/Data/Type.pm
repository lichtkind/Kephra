use v5.20;
use warnings;

# store of standard types, owners (packages can add and remove types)

package Kephra::Base::Data::Type;
our $VERSION = 0.1;
use Kephra::Base::Data::Type::Simple;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Standard qw/:all/;;
use Exporter 'import';
my $TYPE = [qw/new_type check_type guess_type is_type_known/];
our @EXPORT_OK = (@$TYPE);
our %EXPORT_TAGS = (all => [@EXPORT_OK], type => $TYPE);

################################################################################

Kephra::Base::Data::Type::Standard::init;

1;

use v5.20;
use warnings;

# organize  and foreward type related symbols

package Kephra::Base::Data::Type;
our $VERSION = 0.1;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Standard qw/:all/;;
use Exporter 'import';
our @EXPORT_OK = qw/new_type check_type guess_type is_type_known/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

################################################################################

Kephra::Base::Data::Type::Standard::init;

1;

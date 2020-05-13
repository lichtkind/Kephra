use v5.20;
use warnings;

# organize type related symbols

package Kephra::Base::Data::Type;
our $VERSION = 0.2;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;
use Kephra::Base::Data::Type::Standard;
use Exporter 'import';
our @EXPORT_OK = qw/new_type check_type guess_type is_type_known/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $standard_types;
my $shared_types;

################################################################################

Kephra::Base::Data::Type::Standard::init;

6;

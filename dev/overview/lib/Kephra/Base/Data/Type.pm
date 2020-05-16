use v5.20;
use warnings;

# organize type related symbols

package Kephra::Base::Data::Type;
our $VERSION = 0.3;

use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;
use Kephra::Base::Data::Type::Standard;


sub standard      {} #
sub shared        {} #

sub new_type      {} #
sub check_type    {} #
sub guess_type    {} #
sub is_type_known {} #

6;

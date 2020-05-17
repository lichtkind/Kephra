use v5.20;
use warnings;

# organize type related symbols

package Kephra::Base::Data::Type;
our $VERSION = 0.3;

use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;
use Kephra::Base::Data::Type::Standard;


sub standard      {} #                  -->  .type_store
sub shared        {} #                  -->  .type_store

sub create_type   {} # %type_def        -->  .type
sub check_type    {} # ~type $value     -->  ~errormsg
sub guess_type    {} # $value           --> @~type
sub is_type_known {} # ~type ~parameter --> ?

6;

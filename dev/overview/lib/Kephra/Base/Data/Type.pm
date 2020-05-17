use v5.20;
use warnings;

# organize type related symbols

package Kephra::Base::Data::Type;
our $VERSION = 0.5;

use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;
use Kephra::Base::Data::Type::Standard;


sub standard      {} #                  -->  .type_store
sub shared        {} #                  -->  .type_store
sub class_names   {} #                  --> @~type_class

sub create        {} #                                    alias:
sub create_type   {} # %type_def        -->  .type
sub check         {} #                                    alias:
sub check_type    {} # ~type $value     -->  ~errormsg
sub guess         {} #                                    alias:
sub guess_type    {} # $value           --> @~type
sub is_known      {} #                                    alias:
sub is_type_known {} # ~type ~parameter --> ?

6;

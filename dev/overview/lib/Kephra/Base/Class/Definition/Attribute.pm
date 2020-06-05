use v5.20;
use warnings;

# switch for kinds of attribute definitions

package Kephra::Base::Class::Definition::Attribute;
our $VERSION = 0.5;

use Kephra::Base::Class::Definition::Attribute::Data;
use Kephra::Base::Class::Definition::Attribute::Delegating;
use Kephra::Base::Class::Definition::Attribute::Wrapping;


sub new      {} # ~pkg ~name %properties       --> ._| ~errormsg          ._ = attr_data|deleg|wrap


1;

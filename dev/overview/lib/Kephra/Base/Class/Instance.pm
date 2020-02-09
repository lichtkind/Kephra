use v5.16;
use warnings;

package Kephra::Base::Class::Instance;
our $VERSION = 0.02;

use Kephra::Base::Class::Definition;
use Kephra::Base::Class::Scope;
use Kephra::Base::Class::Attribute;
use Kephra::Base::Class::Attribute::Type;

sub create {}            # str class --> bool 
sub delete {}            # $$ obj    --> bool
sub get_by_ref        {} # $$ obj    --> %def
sub get_private_self  {} # $$ obj    --> $$ obj
sub get_access_self   {} # $$ obj    --> $$ obj
sub get_attribute     {} # $$ obj    --> $$ attr

2;

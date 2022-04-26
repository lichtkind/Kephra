use v5.16;
use warnings;

# create methods, accessor stubs are created from Kephra::Base::Class::Instance::Attribute 
# organize their hooks

package Kephra::Base::Class::Build::Attribute;

use Kephra::Base::Package;


sub create_constructor       {} # class method params code     --> error
sub create_destructor        {} # class method params code       --> error
sub create                   {} # class method params code scope   --> error
sub create_multi             {} # class method @$details             --> error
sub create_accessor          {} # class method attribute @$details     --> error
sub create_default_accessors {} # class method attribute type scope      --> error
sub create_delegator         {} # class method params code attribute scope --> error
sub create_default_delegator {} # class method params code attribute scope   --> error


1;


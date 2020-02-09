use v5.16;
use warnings;

package Kephra::Base::Object::Attribute;
use Kephra::API   qw/:log/;
use Kephra::Base::Data::Type;

sub value {}


1;

__DATA__

   get     => {gettername => scope, }
   set     => {settername => scope, }
   default => val
   type    => str+
   help    => str+



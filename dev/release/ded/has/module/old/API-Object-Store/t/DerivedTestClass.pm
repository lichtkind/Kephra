use v5.14;
use warnings;

package DerivedTestClass;
use parent qw(TestClass);

sub new {bless { key => 'val', init => $_[1]}}


1;

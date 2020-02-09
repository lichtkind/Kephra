use v5.14;
use warnings;

package TestClass;

sub new {bless { key => 'val', init => $_[1]}}
sub ret { shift; @_ }
sub one { 1 }
sub init{$_[0]->{init}}
sub get {$_[0]->{key}}
sub set {$_[0]->{key} = $_[1]}

1;

use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Method;
our $VERSION = 0.2;
use Kephra::Base::Class::Definition::Method::Signature;

sub new           {} # ~name %sig_def ~code >@keywords     --> _
sub state         {} # _                                   --> %state
sub restate       {} # %state                              --> _
sub adapt_to_class{} # _                                   --> ~errormsg

1;

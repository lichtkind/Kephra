use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Method::Signature;
our $VERSION = 0.2;
use Kephra::Base::Data::Type;

sub new            {} # %def                       --> _
sub state          {} # $_                         --> %state
sub restate        {} # %state                     --> _

sub adapt_to_class {} # ~class {~attr => ~type}, >@.store --> ~errormsg



1;

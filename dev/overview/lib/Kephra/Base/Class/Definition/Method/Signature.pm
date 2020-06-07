use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Method::Signature;
our $VERSION = 0.1;


sub new         {} # %def     --> _
sub state       {} # $_       --> %state
sub restate     {} # %state   --> _

sub check_types {} # {~attr => ~type}, >@.store



1;

use v5.16;
use warnings;

package Kephra::Base::Class::Builder::Method::Hook;
use Kephra::API qw/:log/;

use Kephra::Base::Package;
use Kephra::Base::Class::Scope;

sub create_anchor {} # class method                       --> %&anchors|err
sub has_anchor    {} # class method                       --> bool

sub add           {} # class method slot hook code code2? --> 0|err
sub remove        {} # class method      hook             --> code,code2?|err
sub is_known      {} # class method      hook             --> slot|0
sub list          {} # class method slot?                 --> @hook

1;

__END__



 - (multi) method
    BEFORE, BEFORE_AND: self params
    AFTER:              self params retval
    AFTER_AND:          self params retval hookret

 - getter

 - auto getter

 - setter

 - auto setter

 - delegator
 
 - auto delegator

 - obj delegator
 
 - auto obj delegator

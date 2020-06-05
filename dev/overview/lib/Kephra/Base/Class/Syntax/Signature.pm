use v5.16;
use warnings;

# parsing signatures into data structure to build definition object from

package Kephra::Base::Class::Syntax::Signature;
our $VERSION = 1.0;

sub parse              {} #   ~sig  --> @params  = [=req, =opt, =ret, @@par] @par = [~name T 'kind' ~name? T]
sub split_args         {} #
sub split_arg_parts    {} #
sub eval_special_syntax{} #

1;

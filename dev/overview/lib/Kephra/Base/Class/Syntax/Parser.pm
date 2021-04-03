use v5.16;
use warnings;

# handling everything about method signatures
# sig: type required_parameter_name - type optional_parameter_name --> ret_type

package Kephra::Base::Class::Syntax::Parser;

sub import    {} # establish new keywords
sub unimport  {} # remove them

sub closing_brace_pos {}

1;

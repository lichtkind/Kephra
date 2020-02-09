use v5.16;
use warnings;

# handling everything about method signatures
# sig: type required_parameter_name - type optional_parameter_name --> ret_type

package Kephra::Base::Class::Method::Signature;

sub parse                    {} #     sig  --> %params
sub types_needed             {} # %params  --> @types
sub create_type_check        {} # %params  --> &incheck, &outcheck


1;
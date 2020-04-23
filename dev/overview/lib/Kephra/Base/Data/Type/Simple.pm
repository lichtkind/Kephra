use v5.20;
use warnings;

# data type object that compiles a coderef (type checker) and can serialize

package Kephra::Base::Data::Type::Simple;

sub new                {} # ~name ~help ~code $default - .parent --> .type | ~errormsg # optionally as %args
sub restate            {} # %state                               --> .type | ~errormsg
sub state              {} # .type                 --> %state
sub get_name           {} # .type                 --> ~name
sub get_default_value  {} # .type                 --> $default
sub get_check_pairs    {} # .type                 --> @checks   # [help, code, ..]
sub check              {} # .type $val            --> ~errormsg

1;

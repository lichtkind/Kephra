use v5.20;
use warnings;

# serializable data type object that compiles a coderef (type checker)

package Kephra::Base::Data::Type::Simple;
our $VERSION = 1.2;

sub new                {} # ~name ~help ~code - .parent $default --> .type | ~errormsg # optionally as %args # required: ~name & (.parent | ~help ~code $default)
sub restate            {} # %state                               --> .type | ~errormsg
sub state              {} # .type                 --> %state
sub assemble_code      {} # .type                 --> ~checkcode

sub get_name           {} # .type                 --> ~name
sub get_default_value  {} # .type                 --> $default
sub get_check_pairs    {} # .type                 --> @checks   # [help, code, ..]
sub get_checker        {} # .type                 --> &checker

sub check              {} # .type $val            --> ~errormsg

1;

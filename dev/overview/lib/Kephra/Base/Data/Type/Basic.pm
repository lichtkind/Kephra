use v5.20;
use warnings;

# serializable data type object that compiles a coderef (type checker)

package Kephra::Base::Data::Type::Basic;
our $VERSION = 1.4;

                          # %typedef = { ~name ~help ~code - .parent|%typedef $default }
sub new                {} # ~name ~help ~code - .parent|%typedef $default    --> .btype | ~errormsg  # required: ~name & (.parent | ~help ~code $default)
sub restate            {} # %state                                           --> .btype | ~errormsg
sub state              {} # .btype                                           --> %state
sub assemble_code      {} # .btype                                           --> ~checkcode

sub get_name           {} # .btype                 --> ~name
sub get_default_value  {} # .btype                 --> $default
sub get_check_pairs    {} # .btype                 --> @checks   # [help, code, ..]
sub get_checker        {} # .btype                 --> &checker

sub check              {} # .btype $val            --> ~errormsg

1;

use v5.20;
use warnings;

# serializable data type object that compiles a coderef (type checker)

package Kephra::Base::Data::Type::Basic;
our $VERSION = 1.4;

                          # %typedef = { ~name ~help ~code - .parent|%typedef $default }
sub new                {} # ~name ~help ~code - .parent|%typedef $default    --> ._ | ~errormsg  # required: ~name & (.parent | ~help ~code $default)
sub restate            {} # %state                                           --> ._ | ~errormsg
sub state              {} # ._                                               --> %state
sub assemble_code      {} # ._                                               --> ~checkcode

sub get_name           {} # ._                     --> ~name
sub get_default_value  {} # ._                     --> $default
sub get_check_pairs    {} # ._                     --> @checks   # [help, code, ..]
sub get_checker        {} # ._                     --> &checker

sub check              {} # ._  $val               --> ~errormsg

1;

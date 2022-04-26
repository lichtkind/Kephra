use v5.20;
use warnings;

# serializable data type object that compiles a coderef (type checker)

package Kephra::Base::Data::Type::Basic;
our $VERSION = 1.6;

                          # %typedef = { ~name ~help ~code - .parent|%typedef $default }
sub new                {} # ~name ~help ~code - .parent|%typedef $default    --> ._ | ~errormsg  # required: ~name & (.parent | ~help ~code $default)
sub restate            {} # %state                                           --> ._ | ~errormsg
sub state              {} # -                                                --> %state
sub assemble_code      {} # -                                                --> ~checkcode

sub get_name           {} # -                      --> ~name
sub get_default_value  {} # -                      --> $default
sub get_parents        {} # -                      --> @_parent.name
sub get_check_pairs    {} # -                      --> @checks   # [help, code, ..]
sub get_checker        {} # -                      --> &checker

sub has_parent         {} # - ~name                --> ?
sub check              {} # -  $val                --> ~errormsg

1;

use v5.20;
use warnings;

# serializable data type object that compiles perl code into a coderef (type checker)

package Kephra::Base::Data::Type::Basic;
our $VERSION = 1.9;

                          # %typedef = { ~name ~help ~code - .parent|%typedef $default }
sub new                {} # ~name ~help ~code - .parent $default    --> ._ | ~errormsg  # required: ~name & (.parent | ~help ~code $default)
sub restate            {} # %state                                  --> ._ | ~errormsg
sub state              {} # _                                       --> %state

#### getter ####################################################################
sub kind               {} # _                      --> 'basic'|'param'
sub name               {} # _                      --> ~name
sub full_name          {} # _                      --> ~fullname
sub ID                 {} # _                      --> ~name
sub ID_equals          {} # _ $typeID              --> ?
sub parents            {} # _                      --> @parent~name
sub has_parent         {} # _ - ~parent            --> ?
sub parameter          {} # _                      --> ''
sub default_value      {} # _                      --> $default
sub help               {} # _                      --> ~help
sub code               {} # _                      --> ~code
sub source             {} # _                      --> @checks   # [help, code, ..]
sub assemble_source    {} # _                      --> ~checkcode

#### public API ################################################################
sub checker            {} # _                      --> &checker
sub check_data         {} # _  $val                --> ?~!

1;

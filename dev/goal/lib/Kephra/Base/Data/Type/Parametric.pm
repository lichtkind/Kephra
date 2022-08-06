use v5.20;
use warnings;

# data type depending second value (parameter) 
# example : valid index (positive int) of an actual array (parameter)

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 1.8;
use Kephra::Base::Data::Type::Basic;

                           #               %parameter = %btypedef|.basic_type
                           #                                 .parent = .basic_type|.param_type
sub new                 {} # ~name  ~help  %parameter ~code .parent - $default --> .param_type | ~errormsg  # optionally as %args
sub state               {} # -                                                  --> %state                     serializei into data
sub restate             {} # %state                                             --> .param_type                recreate all type checker from data dump

#### getter ####################################################################
sub kind               {} # _                           --> 'basic'|'param'
sub name               {} # _                           --> ~name
sub full_name          {} # _                           --> ~fullname
sub ID                 {} # _                           --> ~name
sub ID_equals          {} # _ $typeID                   --> ?
sub parents            {} # _                           --> @parent~name
sub has_parent         {} # _ ~BTname|[~PTname ~BTname] -->  ?
sub parameter          {} # _                           --> ''
sub default_value      {} # _                           --> $default
sub help               {} # _                           --> ~help
sub code               {} # _                           --> ~code
sub source             {} # _                           --> @checks   # [help, code, ..]
sub assemble_source    {} # _                           --> ~checkcode

#### public API ################################################################
sub checker            {} # _                           --> &checker
sub check_data         {} # _  $val                     --> ~errormsg|''

1;

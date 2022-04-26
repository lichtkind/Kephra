use v5.20;
use warnings;

# data type depending second value (parameter) 
# example : valid index (positive int) of an actual array (parameter)

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 1.5;
use Kephra::Base::Data::Type::Basic;

                           #               %parameter = %btypedef|.basic_type
                           #                                 .parent = .basic_type|.param_type
sub new                 {} # ~name  ~help  %parameter  ~code .parent - $default --> .param_type | ~errormsg  # optionally as %args
sub state               {} # -                                                  --> %state                     serializei into data
sub restate             {} # %state                                             --> .param_type                recreate all type checker from data dump

sub get_name            {} # -                                                  -->  ~name
sub get_help            {} # -                                                  -->  ~help
sub get_default_value   {} # -                                                  -->  $default
sub get_parameter       {} # -                                                  -->  .basic_type
sub get_parents         {} # -                                                  -->  %_parent.name->_parent_parameter_name
sub get_checker         {} # -                                                  -->  &check
sub get_trusting_checker{} # -                                                  -->  &trusting_check    # when parameter is already type checked

sub has_parent          {} # - ~basic_name|[~name ~param_name]                  -->  ?
sub check               {} # -  $val $param                                     -->  ~errormsg


1;

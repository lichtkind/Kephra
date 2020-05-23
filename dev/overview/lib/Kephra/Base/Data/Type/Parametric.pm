use v5.20;
use warnings;

# data type depending second value (parameter) 
# example : valid index (positive int) of an actual array (parameter)

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 1.3;
use Kephra::Base::Data::Type::Basic;

                           #               %parameter = %btypedef|.basic_type
                           #                                 .parent = .basic_type|.param_type
sub new                 {} # ~name  ~help  %parameter  ~code .parent - $default --> .param_type | ~errormsg  # optionally as %args
sub state               {} # ._                                                 --> %state                     serializei into data
sub restate             {} # %state                                             --> .param_type                recreate all type checker from data dump

sub get_name            {} # ._                                                 -->  ~name
sub get_help            {} # ._                                                 -->  ~help
sub get_default_value   {} # ._                                                 -->  $default
sub get_parameter       {} # ._                                                 -->  .basic_type
sub get_checker         {} # ._                                                 -->  &check
sub get_trusting_checker{} # ._                                                 -->  &trusting_check    # when parameter is already type checked

sub check               {} # ._  $val $param                                    -->  ~errormsg


1;

use v5.20;
use warnings;

# data type depending second value (parameter) 
# example : valid index (positive int) of an actual array (parameter)

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 1.2;
use Kephra::Base::Data::Type::Basic;

                           #               %parameter = .btype | %{type = .btype - ~name $default }
                           #                                 .parent = .btype|.ptype
sub new                 {} # ~name  ~help  %parameter  ~code .parent - $default --> .ptype | ~errormsg  # optionally as %args
sub state               {} # .ptype                                             --> %state                serialize
sub restate             {} # %state                                             --> .ptype                recreate all type checker from data dump

sub get_name            {} # .ptype                                             -->  ~name
sub get_help            {} # .ptype                                             -->  ~help
sub get_default_value   {} # .ptype                                             -->  $default
sub get_parameter       {} # .ptype                                             -->  .type              # KB::Data::Type::Simple
sub get_checker         {} # .ptype                                             -->  &check
sub get_trusting_checker{} # .type                                              -->  &trusting_check    # when parameter is already type checked

sub check               {} # .ptype $val $param                                 -->  ~errormsg


1;

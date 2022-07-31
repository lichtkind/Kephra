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

sub name               {} # -                      --> ~name
sub ID                 {} # -                      --> ~name
sub default_value      {} # -                      --> $default
sub parents            {} # -                      --> @_parent.name
sub check_pairs        {} # -                      --> @checks   # [help, code, ..]
sub checker            {} # -                      --> &checker

sub has_parent         {} # - ~name                --> ?
sub check_data         {} # -  $val                --> ~errormsg

#### getter ####################################################################
sub kind           { 'basic' }                    # _                  -->  'basic'|'param'
sub ID             { $_[0]->{'name'} }            # _                  -->  ~name
sub ID_equals      {(defined $_[1] and not ref $_[1] and $_[0]->ID eq $_[1] ) ? 1 : 0 } # _ $typeID  -->  ?
sub name           { $_[0]->{'name'} }            # _                  -->  ~name
sub full_name      { $_[0]->{'name'} }            # _                  -->  ~name
sub help           { $_[0]->{'checks'}[-2] }      # _                  -->  ~help
sub code           { $_[0]->{'checks'}[-1] }      # _                  -->  ~code
sub parents        { @{$_[0]->{'parents'}} }      # _                  -->  @:parent~name
sub parameter      { '' }                         # _                  -->  ''  # make API compatible
sub has_parent     { $_[1] ~~ $_[0]->{'parents'} }# _  ~parent         -->  ?
sub source         { $_[0]->{'checks'} }          # _                  -->  @checks
sub default_value  { $_[0]->{'default'} }         # _                  -->  $default
sub checker        { $_[0]->{'coderef'} }         # _                  -->  &checker
#### public API ################################################################
sub check_data     { $_[0]->{'coderef'}->($_[1]) }# _  $val            -->  '' | ~errormsg
sub assemble_code { _asm_($_[0]->name, $_[0]->source) }

1;

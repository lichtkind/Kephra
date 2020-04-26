use v5.20;
use warnings;

# KBOS data types, standards + added by any package (owner)
# serialize keys: check, shortcut, default, file, package

package Kephra::Base::Data::Type;

sub init              {} #                    compile default types
sub state             {} #        --> %state  dump all active types data
sub restate           {} # %state -->         recreate all type checker from data dump

sub add               {} # ~type ~help ~check - $default ~parent ~shortcut --> ~error
sub delete            {} # ~type                                           --> ~error

sub list_names        {} #                       --> @~type
sub list_shortcuts    {} #                       --> @~shortcut
sub resolve_shortcut  {} #  ~shortcut            -->  ~type

sub known_type        {} #                                       alias:
sub is_known          {} # ~type                 -->  ?
sub is_standard       {} # ~type                 -->  ?
sub is_owned          {} # ~type ~package ~file  -->  ?

sub get_default_value {} # ~type                 -->  $default|undef
sub get_checks        {} # ~type                 -->  @checks  = [[~help, &check]]
sub get_callback      {} # ~type                 -->  &callback|~evalerror

sub check_type        {} #                                         alias:
sub check             {} # ~type $val               -->  ~error    = "reason $val"
sub guess_type        {} #                                         alias:
sub guess             {} # $val                     -->  @~type

1;

__END__

shortcuts

@ arrayref
% hashref
\ any ref
$ value - none ref
~ string
? bool
+ number
\x{00a7} integer
# 
'
"
!
/
^
| type name
-
:
;
=
_


not allowes , ( ) < >  { }

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


my @standard = ( # standard types - no package can delete them
  index => {code =>'return out of range if $_[0] >= @{$_[1]}', arguments =>[{name => 'array', type => 'ARRAY', default => []},], 
            help => 'valid index of array', parent => 'int_pos' },
  typed_array => {code => 'for my $vi (0..$#{$_[0]}){my $ret = $_[1]->($_[0][$vi]); return "array element $vi : $ret" if $ret}',
                  arguments =>[{name => 'type name', type =>'TYPE', default => 'str', eval => 'Kephra::Base::Data::Type::get_callback($_[1])'} ,],
                  help => 'array with typed elements', parent => 'ARRAY', shortcut => '@', },
  typed_hash  => {code => 'for my $vk (keys %{$_[0]}){my $ret = $_[1]->($_[0]{$vk}); return "hash value of key $vk : $ret" if $ret}',
                  arguments =>[{name => 'type name', type =>'TYPE', default => 'str', eval => 'Kephra::Base::Data::Type::get_callback($_[1])'} ,
                  help => 'hash with typed values', parent => 'HASH', shortcut => '%',],},
);
set
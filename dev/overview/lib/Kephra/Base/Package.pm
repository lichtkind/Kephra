use v5.20;
use warnings;

# low level package and sub manipulation in symbol table // export all

package Kephra::Base::Package;

sub package_loaded { } # ~package                   --> bool
sub count_sub      { } # ~package                   --> @subname
sub call_sub       { } # ~package_sub : ~params     --> retval
sub sub_caller     { } # : +depth=1                 --> package sub file line

sub has_sub        { } # ~package ~sub              --> bool
sub has_array      { } # ~package ~array            --> bool
sub has_hash       { } # ~package ~hash             --> bool

sub get_sub        { } # ~package : ~sub            --> &
sub get_array      { } # ~package : ~array          --> @
sub get_hash       { } # ~package : ~hash           --> %

sub set_sub        { } # ~package? ~sub &CODE       --> bool
sub set_array      { } # ~package? ~array @ARRAY    --> bool
sub set_hash       { } # ~package? ~hash %HASH      --> bool


1;

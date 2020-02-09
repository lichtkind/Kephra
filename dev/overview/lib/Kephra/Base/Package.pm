use v5.16;
use warnings;

# low level package and sub manipulation

package Kephra::Base::Package;

sub package_loaded { } # package              --> bool
sub count_sub      { } # package              --> int+
sub has_sub        { } # package sub          --> bool
sub call_sub       { } # package_sub [params] --> retval
sub get_sub        { } # package [sub]        --> CODE
sub set_sub        { } # package? sub coderef --> bool
sub sub_caller     { } # depth=1              --> package sub file line


1;

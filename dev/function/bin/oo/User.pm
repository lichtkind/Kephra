use v5.16;
use warnings;

package User;
use parent 'Class';

sub import { say 'User import: shift -  ', shift, ', caller - ', (scalar caller)}

# sub attribute { say @_ }

# attribute  a => {get => 'set'};

1;

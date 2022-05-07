use v5.16;
use warnings;

package MiniClass;
# use Exporter 'import';

our @EXPORT = qw(attribute);

sub import { say 'Class import: shift -  ', shift, ', caller - ', (scalar caller)}

sub attribute {  say @_ }

1;

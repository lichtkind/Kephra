use v5.16;
use warnings;

package Export1;
use Exporter 'import';
our @EXPORT_OK = qw/one/;

use Export2 qw/two/;

sub one { 1 }

1;

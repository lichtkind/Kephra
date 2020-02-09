use v5.16;
use warnings;

package Export2;
use Exporter 'import';
our @EXPORT_OK = qw/two/;

#use Export1 qw/one/;


sub two { 2 }

1;

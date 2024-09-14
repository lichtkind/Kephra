use v5.16;
use warnings;
use lib '.';

package MAIN;
use Import qw/t1 t2/;
#use Import;

say 'script loads module Import and imports methods t1 and t2';
say 'import test, a "Import", "t1", "t2" and " " should be above';

exit(0);

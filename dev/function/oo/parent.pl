use v5.16;
use warnings;

# test run times for usage of parent pragma

BEGIN { unshift @INC, '.'}

package Child;

say 'will use parent';
use parent 'Parent';
say 'did use parent, will run import';

Parent::import();

say 'exit child';
exit(0);

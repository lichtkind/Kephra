use v5.16;
use warnings;

BEGIN {unshift @INC, '.'}
use Export1;
use Export2;

say Export1::two(), Export2::one();

exit(0);

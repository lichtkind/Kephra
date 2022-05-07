use v5.16;
use warnings;

BEGIN { unshift @INC, '.'  }

package MoClass;
use Mo;

# sub new { bless {} }

has name => ();

1;

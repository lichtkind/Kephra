use v5.16;
use warnings;

BEGIN  { unshift @INC, '.' }

package UsePhaserBefore;

sub import { say 'import '. __PACKAGE__ }

BEGIN     { say 'BEGIN '.__PACKAGE__ }
CHECK     { say 'CHECK '.__PACKAGE__ }
UNITCHECK { say 'UNITCHECK '.__PACKAGE__ }
INIT      { say 'INIT '.__PACKAGE__ }
END       { say 'END '.__PACKAGE__ }
            say 'run '.__PACKAGE__;


1;

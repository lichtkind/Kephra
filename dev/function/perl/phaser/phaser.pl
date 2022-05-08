use v5.16;
use warnings;

package TestRun;
use lib '.';
require RequirePhaserBefore;
use UsePhaserBefore;
use UsePhaserBefore2;

BEGIN     { say 'BEGIN '.__PACKAGE__}
CHECK     { say 'CHECK '.__PACKAGE__ }
UNITCHECK { say 'UNITCHECK '.__PACKAGE__ }
INIT      { say 'INIT '.__PACKAGE__ }
END       { say 'END '.__PACKAGE__ }
            say 'run '.__PACKAGE__;

sub import { 'import ' . __PACKAGE__ }

require RequirePhaserAfter;
use UsePhaserAfter;

exit(0);

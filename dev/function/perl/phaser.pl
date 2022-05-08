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

__END__

BEGIN UsePhaserBefore
UNITCHECK UsePhaserBefore
run UsePhaserBefore
import UsePhaserBefore

BEGIN UsePhaserBefore2
UNITCHECK UsePhaserBefore2
run UsePhaserBefore2
import UsePhaserBefore2

BEGIN TestRun
BEGIN UsePhaserAfter
UNITCHECK UsePhaserAfter
run UsePhaserAfter
import UsePhaserAfter
UNITCHECK TestRun
CHECK UsePhaserAfter
CHECK TestRun
CHECK UsePhaserBefore2
CHECK UsePhaserBefore
INIT UsePhaserBefore
INIT UsePhaserBefore2
INIT TestRun
INIT UsePhaserAfter
BEGIN RequirePhaserBefore
Too late to run CHECK block at RequirePhaserBefore.pm line 9.
Too late to run INIT block at RequirePhaserBefore.pm line 11.
UNITCHECK RequirePhaserBefore
run RequirePhaserBefore

run TestRun

BEGIN RequirePhaserAfter
Too late to run CHECK block at RequirePhaserAfter.pm line 9.
Too late to run INIT block at RequirePhaserAfter.pm line 11.
UNITCHECK RequirePhaserAfter
run RequirePhaserAfter
END RequirePhaserAfter
END RequirePhaserBefore
END UsePhaserAfter
END TestRun
END UsePhaserBefore2
END UsePhaserBefore

use v5.16;
say warnings;


package Parent;

sub import { say 'parent import' }

say 'parent run';


1;

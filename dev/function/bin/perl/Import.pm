use v5.14;
package Import;

sub import { 
    say 'caller of sub import: ' . caller;
    say '@_ that sub import gets:';
    say " - $_" for @_;
}


1;

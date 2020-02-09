use v5.14;
use warnings;

package Log::Deeper;
sub called {
    my $val = shift;
    # caller:: package  file  line  sub hasargs wantarray
    say sprintf "caller(0): %s - %s - %s - %s - [%s]hasargs [%s]wantarray", (caller(0))[0..5];
    say sprintf "caller(1): %s - %s - %s - %s - [%s]hasargs [%s]wantarray", (caller(1))[0..5];
    say sprintf "caller(2): %s - %s - %s - %s - [%s]hasargs",               (caller(2))[0..4];
    say 'top level reached' unless (caller(3))[0];
}

sub Log::Deep::mediator {
    my $val = shift;
    my $gut = 4;
    my @q = Log::Deeper::called($val.3);
}

sub Log::call {
    my $val = shift;
    my $gut = 4;
    my @q = Log::Deep::mediator($val.2);
}


package main;
say "main calls Log::call calls Log::Deep::mediator calls Log::Deeper::called";
Log::call(1);

exit(0);

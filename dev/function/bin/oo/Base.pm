use v5.14;
use warnings;

package Base;

sub new {
    my ($package, @params ) = @_;
    my $self = bless {}, $package;
    $self;
}

sub is_base { 1 }

1;

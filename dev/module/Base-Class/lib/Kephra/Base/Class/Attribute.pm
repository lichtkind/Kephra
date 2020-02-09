use v5.16;
use warnings;

# central kv storage for all data stored in normal (called data)- and wrapping attributes

package Kephra::Base::Class::Attribute;
our $VERSION = 0.04;
use Kephra::Base::Package;

my %value = ();

################################################################################
sub create {
    my ($key, $value) = @_;
    return 0 unless @_ < 3;
    my $k = $key // 0;
    my $self = bless \$k , __PACKAGE__;
    $value{int $self} = $value if defined $value;
    $self;
}
sub is_known { (ref $_[0] and exists $value{int $_[0]}) ? 1 : 0 }
sub get      { $value{int $_[0]}         if is_known($_[0]) }
sub set      { $value{int $_[0]} = $_[1] if is_known($_[0]) }
sub delete   { delete $value{int $_[0]}  if is_known($_[0]) }
################################################################################

1;

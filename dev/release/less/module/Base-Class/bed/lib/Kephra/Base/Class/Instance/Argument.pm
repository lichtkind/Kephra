use v5.16;
use warnings;

# create parameter objects (revieved by methods) and store their values

package Kephra::Base::Class::Instance::Argument;
our $VERSION = 0.01;
use Kephra::Base::Package;
use Kephra::Base::Class::Definition::Scope qw/cat_scope_path/;
my %value;

################################################################################
sub create {
    my ($class, $method, $values) = @_;
    return 0 unless ref $values eq 'HASH' and substr($class, 0, 6) eq 'Kephra';
    my $v = 0;
    my $self = bless \$v , Kephra::Base::Class::Scope::name('argument', $class, $method);
    $value{int $self} = $values;
    $self;
}
sub delete   { delete $value{int $_[0]}  if ref $_[0] and exists $value{int $_[0]} }
sub get_all  { $value{int $_[0]}         if exists $value{int $_[0]} and not defined $_[1] }
sub get_value{
    return unless ref $_[0];
    my $nr = int $_[0];
    $value{$nr}{$_[1]}  if exists $value{$nr} and exists $value{$nr}{$_[1]} and not defined $_[2];
}
################################################################################
sub set_methods {
    my ($class, $method, $parameter) = @_;
    return 0 if ref $parameter ne 'ARRAY' or substr($class, 0, 6) ne 'Kephra';
    for my $p (@$parameter){
        Kephra::Base::Package::set_sub(
            Kephra::Base::Class::Scope::name('argument', $class, $method, $p->[1]),
            sub{get_value(shift, $p->[1])}
        )
    }
    1;
}
################################################################################

1;

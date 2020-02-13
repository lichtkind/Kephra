use v5.16;
use warnings;

# central kv storage for all data stored in normal (called data)- and wrapping attributes

package Kephra::Base::Class::Attribute;
our $VERSION = 0.04;
use Kephra::Base::Package;
use Kephra::Base::Data::Type;

my %value = ();

################################################################################
sub create_accessors {
    my ($class, $attribute, $class_types, $type) = @_;
    my $callback = $class_types->check_callback($type);
    my $default = $class_types->default_value($type);
    return 0 unless ref $callback;

}
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

__END__
my $universal_getter = sub{Kephra::Base::Class::Attribute::get($_[0])};
my (%setter, %resetter);

################################################################################
sub create_attribute_accessors {

    $resetter{$class}{$type} = sub{set($_[0], $default )} unless ref $resetter{$class}{$type};
    $setter{$class}{$type} = sub{   $callback->($_[1], Kephra::Base::Class::Instance::get_access_self($_[0]))
                         or Kephra::Base::Class::Instance::Attribute::set(@_[0,1])} unless ref $setter{$class}{$type};

    Kephra::Base::Package::set_sub( Kephra::Base::Class::Scope::name('attribute',$class,$attribute,'get'), $universal_getter);
    Kephra::Base::Package::set_sub( Kephra::Base::Class::Scope::name('attribute',$class,$attribute,'set'),  $setter{$type});
    Kephra::Base::Package::set_sub( Kephra::Base::Class::Scope::name('attribute',$class,$attribute,'reset'), $resetter{$type});
    1;
}

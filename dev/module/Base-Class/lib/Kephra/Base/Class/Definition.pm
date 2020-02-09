use v5.16;
use warnings;

# central store for all KBOS class definitions (specs, which attr methods and so on)
# delegate calls for class creation; phases: types -> methods -> attributs -> new

package Kephra::Base::Class::Definition;
our $VERSION = 0.01;

my %store;

sub new_class {
    my ($class) = @_;
    return "class $class is already defined" if exists $store{$class};
    $store{$class} = {attribute => { data => {}, delegating => {}, wrapping => {}, },
                         method => { simple => {}, multi => {}, accessor => {}, constructor => {}, destructor =>{} },
                       complete => 0, unresolved => 0};
    '';
}

sub add_data_attribute {
    my ($class, $name, $properties) = @_;
    return 0 unless $store{$class} and not $store{$class}{'c'} and $store{$class}{'types'}->is_known($type);
    return 0 if exists $store{$class}{'attribute'}{$attribute} or exists $store{$class}{'object_attribute'}{$attribute};
    $store{$class}{attribute}{$attribute} = $type;
    Kephra::Base::Class::Method::create_attribute_accessors($class, $attribute, $type, $store{$class}{types});
    1;
}
sub add_delegating_attribute {
    my ($class, $name, $properties) = @_;
    return 0 unless $store{$class} and not $store{$class}{c};
    return 0 if exists $store{$class}{attribute}{$attribute} or exists $store{$class}{object_attribute}{$attribute};
    return 0 if $methods and ref $methods ne 'ARRAY';
    $methods = [] unless defined $methods;
    push @$methods, 'new', 'destroy';
    $new     = undef if $new and Kephra::Base::Data::Type::check('ARRAY', $new);
    $destroy = undef if $destroy and Kephra::Base::Data::Type::check('ARRAY', $destroy);
    $store{$class}{object_attribute}{$attribute}
        = { class => $attr_class, new => ($new||[]), destroy => ($destroy||[]), methods => [@$methods]};
    1;
}
sub add_wrapping_attribute {
    my ($class, $name, $properties) = @_;

}

sub add_simple_method {
    my ($class, $name, $signature, $scope) = @_;
}
################################################################################
sub resolve_dependencies {
    my ($class) = @_;
    return 0 unless $store{$class};
    return 1 if $store{$class}{r};
    for my $attr (values %{$store{$class}{object_attribute}}){
        for (@{$attr->{methods}}){
            return 0 unless Kephra::Base::Package::has_sub($attr->{class}, $_)
        }
    }
    $store{$class}{r} = 1;
}

sub get_attribute_type       { $store{$_[0]}{attribute}{$_[1]} if exists $store{$_[0]} }
sub get_attributes           { $store{$_[0]}{attribute}        if exists $store{$_[0]} }
sub get_delegating_attributes{ $store{$_[0]}{delegating}       if exists $store{$_[0]} }
sub get_wrapping_attributes  { $store{$_[0]}{wrapping}         if exists $store{$_[0]} }
sub get_types                { $store{$_[0]}{types}            if exists $store{$_[0]} }

sub complete    {
    return 0 unless exists $store{$_[0]} and not exists $store{$_[0]}{c}; $store{$_[0]}{c} = 1;
}
sub is_complete {                 exists $store{$_[0]} and            $store{$_[0]}{c} }
sub is_known    {                 exists $store{$_[0]} }
################################################################################



1;

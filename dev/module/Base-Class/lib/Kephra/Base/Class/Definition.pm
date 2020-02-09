use v5.16;
use warnings;

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
    return 0 unless $set{$class} and not $set{$class}{c} and $set{$class}{types}->is_known($type);
    return 0 if exists $set{$class}{attribute}{$attribute} or exists $set{$class}{object_attribute}{$attribute};
    $set{$class}{attribute}{$attribute} = $type;
    Kephra::Base::Class::Instance::Attribute::create_methods($class, $attribute, $type, $set{$class}{types});
    1;
}
sub add_delegating_attribute {
    my ($class, $name, $properties) = @_;
    return 0 unless $set{$class} and not $set{$class}{c};
    return 0 if exists $set{$class}{attribute}{$attribute} or exists $set{$class}{object_attribute}{$attribute};
    return 0 if $methods and ref $methods ne 'ARRAY';
    $methods = [] unless defined $methods;
    push @$methods, 'new', 'destroy';
    $new     = undef if $new and Kephra::Base::Data::Type::check('ARRAY', $new);
    $destroy = undef if $destroy and Kephra::Base::Data::Type::check('ARRAY', $destroy);
    $set{$class}{object_attribute}{$attribute}
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
    return 0 unless $set{$class};
    return 1 if $set{$class}{r};
    for my $attr (values %{$set{$class}{object_attribute}}){
        for (@{$attr->{methods}}){
            return 0 unless Kephra::Base::Package::has_sub($attr->{class}, $_)
        }
    }
    $set{$class}{r} = 1;
}

sub get_attribute_type       { $set{$_[0]}{attribute}{$_[1]} if exists $set{$_[0]} }
sub get_attributes           { $set{$_[0]}{attribute}        if exists $set{$_[0]} }
sub get_delegating_attributes{ $set{$_[0]}{delegating}       if exists $set{$_[0]} }
sub get_wrapping_attributes  { $set{$_[0]}{wrapping}         if exists $set{$_[0]} }
sub get_types                { $set{$_[0]}{types}            if exists $set{$_[0]} }

sub complete    {
    return 0 unless exists $set{$_[0]} and not exists $set{$_[0]}{c}; $set{$_[0]}{c} = 1;
}
sub is_complete {                 exists $set{$_[0]} and            $set{$_[0]}{c} }
sub is_known    {                 exists $set{$_[0]} }
################################################################################



1;

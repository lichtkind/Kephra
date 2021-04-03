use v5.20;
use warnings;

# central storage for all class definitions and their instances

package Kephra::Base::Class::Registry;
our $VERSION = 0.00;


my %object = (); # register of all objects by class name
my %by_ref = (); # cross ref
my %parent = (); # ref to parent object

################################################################################

1;
__END__

sub is_class_known { 
}

sub complete    { return 0 unless exists $set{$_[0]} and not exists $set{$_[0]}{c}; $set{$_[0]}{c} = 1;}
sub is_complete {                 exists $set{$_[0]} and            $set{$_[0]}{c} }
sub is_known    {                 exists $set{$_[0]} }


sub import { Kephra::Base::Class::Syntax::import(shift) }

sub create {
    my ($class) = @_;
    return 0 if substr($class, 0, 6) ne 'Kephra' or defined $set{$class};
    $set{$class} = {attribute => {}, types => Kephra::Base::Class::Type->new($class)}; #method => {}, 
    1;
}
sub add_attribute {
    my ($class, $attribute, $type) = @_;
    return 0 unless $set{$class} and not $set{$class}{c} and $set{$class}{types}->is_known($type);
    return 0 if exists $set{$class}{attribute}{$attribute} or exists $set{$class}{object_attribute}{$attribute};
    $set{$class}{attribute}{$attribute} = $type;
    Kephra::Base::Class::Instance::Attribute::create_methods($class, $attribute, $type, $set{$class}{types});
    1;
}
sub add_object_attribute {
    my ($class, $attribute, $attr_class, $new, $destroy, $methods) = @_;
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
    my ($class, $attribute, $attr_class, $new, $destroy, $methods) = @_;

}

sub add_method {
    my ($class, $method, $signature, $scope) = @_;

}
################################################################################
sub resolve_deps {
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

################################################################################
1;

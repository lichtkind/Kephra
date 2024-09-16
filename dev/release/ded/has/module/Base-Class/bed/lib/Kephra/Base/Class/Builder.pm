use v5.18;
use warnings;

# delegate calls for class creation; phases: types -> methods -> attributs -> new

package Kephra::Base::Class::Build;
our $VERSION = 0.02;
my (%raw_def); # class kind name [parameter]
use Kephra::Base::Package;
use Kephra::Base::Class::Attribute;
use Kephra::Base::Class::Definition;
use Kephra::Base::Class::Scope;
use Kephra::Base::Class::Method;
use Kephra::Base::Class::Instance;
use Kephra::Base::Class::Interface;
use Kephra::Base::Class::Type;

sub make {
    return unless $_[1]; # min 2 params
    state ($class_types, $private_self, $attr);
    my $what = shift;
    if ($what eq 'class'){
        my $class = shift;
        die "class $class already created" if exists $raw_def{ $class };
        Kephra::Base::Class::create($class ) or die 'class already created';
        $raw_def{ $class } = {method =>{clone => 1, state => 1, restate => 1 }}; # default service routines
    }
    elsif ($what eq 'type') {
        my ($class, $type, $def) = @_;
        $raw_def{ $class }{$what}{$type} = $def unless Kephra::Base::Data::Type::add($type, $def);
    }
    elsif ($what eq 'subtype'){
        my ($class, $type, $def) = @_;
        $raw_def{ $class }{$what}{$type} = $def unless Kephra::Base::Class::get_types($class)->add($type, $def);
    }
    elsif ($what eq 'method') {
        my ($class, $method, $params, $code, $property) = @_;
        my $scope = ($property->{private} ? 'private' : 'public');
        if ($property->{multi}){
            die "class $class already has method $method" if $raw_def{ $class }{method}{$method};
            push @{$raw_def{ $class }{multi}{$method}}, [$params, $code, $scope];
        } else {
            die "class $class already has method $method" if $raw_def{ $class }{all_method}{$method};
            $raw_def{ $class }{method}{$method} = [$params, $code, $scope];
        }
        $raw_def{ $class }{all_method}{$method}++;
    }
    elsif ($what eq 'getter' or $what eq 'setter' or $what eq 'delegator') {
        my ($class, $method, $params, $code) = @_;
        die "class $class already has a method named $method" if $raw_def{ $class }{all_method}{$method};
        $raw_def{ $class }{$what}{$method} = [$params, $code];
        $raw_def{ $class }{all_method}{$method}++;
    }
    elsif ($what eq 'attribute'){
        my ($class, $attr, $def, $property) = @_;
        die "definition of attribute $class::$attr is incomplete" unless ref $property;
        die "class $class has $what named $attr declared twice" if $raw_def{ $class }{$what}{$attr};
        die "name of $what $class::$attr is already used" if $raw_def{ $class }{all_method}{$attr};
        if ($property->{object}) {$raw_def{ $class }{object_attr}{$attr} = $def}
        else                     {$raw_def{ $class }{attribute}{$attr} = $def}
        $raw_def{ $class }{all_method}{$attr}++;
    }
    elsif ($what eq 'finalize'){
        my $class = shift;
        my $def = $raw_def{ $class };
        my $error;
        while (my $cc = my @t = keys %{$def->{type}}){
            for (@t){ delete $def->{type}{$_} if Kephra::Base::Data::Type::add($_, $def->{type}{$_}) }
            die "can not resolve types: @t of class $class" if $cc == keys %{$def->{type}};
        }
        while (my $cc = my @t = keys %{$def->{subtype}}){
            for (@t){ delete $def->{type}{$_} if Kephra::Base::Class::Instance::get_types($class)->add($_, $def->{type}{$_}) }
            die "can not resolve class types: @t of class $class" if $cc == keys %{$def->{subtype}};
        }
        my (@required_attr, @optional_attr, @mapped_methods) = ((),(),());
        for my $attr_name (sort keys %{$def->{attribute}}){
            my $attr = $def->{attribute}{$attr_name};
            die "attribute $class::$attr_name definition needs type, getter or setter and a help text"
                unless exists $attr->{type} and exists $attr->{help} and exists $attr->{get} and exists $attr->{set};
            Kephra::Base::Class::add_attribute($class, $attr_name, $attr->{type})
                or die "attribute $attr_name of class $class has type: $attr->{type} which is not valid";
            if ($attr->{ required }){ push @required_attr, [$attr->{type}, $attr_name] }
            else                    { push @optional_attr, [$attr->{type}, $attr_name] }
            for my $setter (keys %{$attr->{set}}){
                 if (substr($setter, 0, 1) eq '-'){
                    my $scope = (exists $attr->{get}{$setter})
                        ? {get => $attr->{get}{$setter}, set => $attr->{set}{$setter}}
                        : {                              set => $attr->{set}{$setter}};
                    $setter = substr($setter,1);
                    die "class $class already has method $setter" if $def->{all_method}{$setter};
                    $def->{all_method}{$setter}++;
                    $error = Kephra::Base::Class::Method::create_default_accessors ($class, $setter, $attr_name, $attr->{type}, $scope);
                } else {
                    die "setter $setter declared but not implemented" unless ref $raw_def{ $class }{setter}{$setter};
                    push @{$raw_def{ $class }{setter}{$setter}}, $attr->{set}{$setter};
                    if (exists $attr->{get}{$setter}){
                        die "getter $setter declared but not implemented" unless ref $raw_def{ $class }{getter}{$setter};
                        push @{$raw_def{ $class }{getter}{$setter}}, $attr->{get}{$setter};
                        $error = Kephra::Base::Class::Method::create_accessor($class, $setter, $attr_name, [$raw_def{ $class }{setter}{$setter},
                                                                                                            $raw_def{ $class }{getter}{$setter}]);
                    } else {
                        $error = Kephra::Base::Class::Method::create_accessor($class, $setter, $attr_name, [$raw_def{ $class }{setter}{$setter}]);
                    }
                }
                die $error if $error;
                push @mapped_methods, ['PARAMETER', $setter];
            }
           for my $getter (keys %{$attr->{get}}){
                 next if exists $attr->{set}{$getter};
                if (substr($getter, 0, 1) eq '-'){
                    $getter = substr($getter,1);
                    die "class $class already has method $getter" if $def->{all_method}{$getter};
                    $def->{all_method}{$getter}++;
                    $error = Kephra::Base::Class::Method::create_default_accessors
                        ($class, $getter, $attr_name, $attr->{type}, {get => $attr->{get}{'-'.$getter}});
                } else {
                    die "getter $getter declared but not implemented" unless ref $raw_def{ $class }{getter}{$getter};
                    push @{$raw_def{ $class }{getter}{$getter}}, $attr->{get}{$getter};
                    $error = Kephra::Base::Class::Method::create_accessor($class, $getter, $attr_name, [$raw_def{ $class }{getter}{$getter}]);
                }
                die $error if $error;
            }
        }
        for my $attr_name (sort keys %{$def->{object_attr}}){
            my $attr = $def->{object_attr}{$attr_name};
            my $extected_methods = [];
            die "object attribute $class::$attr_name definition needs class, delegators and a help text"
                unless exists $attr->{class} and exists $attr->{help} and exists $attr->{delegate};
            die "object attribute $class::$attr_name is rekursive" if $class eq $attr->{class};
            # TODO : check for full cycle recursion
            for my $delegator (keys %{$attr->{delegate}}){
                 if (substr($delegator, 0, 1) eq '-'){
                    my $scope = $attr->{delegate}{$delegator};
                    my $method = substr($delegator,1);
                    if (ref $scope eq 'HASH'){
                        $method = $scope->{rename};
                        $scope = $scope->{scope};
                    }
                    $delegator = substr($delegator,1);
                    die "class $class already has method $method" if $def->{all_method}{$method};
                    $def->{all_method}{$method}++;
                    push @$extected_methods, $method;
                    $error = Kephra::Base::Class::Method::create_default_delegator($class, $delegator, $attr->{class}, $method, $attr_name, $scope);
                } else {
                    $error = Kephra::Base::Class::Method::create_delegator
                        ($class, $delegator, @{$raw_def{$class}{delegator}{$delegator}}, $attr_name, $attr->{delegate}{$delegator});
                }
                die $error if $error;
                push @mapped_methods, ['PARAMETER', $delegator];
            }
            Kephra::Base::Class::add_object_attribute($class, $attr_name, $attr->{class}, $attr->{new}, $attr->{destroy}, $extected_methods)
                or die "attribute $attr_name of class $class has type: $attr->{class} which is not valid";

        }
         for (keys %{$def->{multi}}){
            die "class $class::$_ must not be a multi" if $_ eq 'new' or $_ eq 'destroy';
            $error = Kephra::Base::Class::Method::create_multi($class, $_, $def->{multi}{$_});
            die $error if $error;
        }
        for (keys %{$def->{method}}) {
            next if $_ eq 'new' or $_ eq 'destroy';
            $error = Kephra::Base::Class::Method::create($class, $_, @{$def->{method}{$_}});
            die $error if $error;
        }
        if ($def->{method}{'new'}){
            $error = Kephra::Base::Class::Method::create_destructor($class, 'new', @{$def->{method}{'new'}});
        } else { $error = Kephra::Base::Class::Method::create_default_constructor(
                 $class, 'new',{required_nr => scalar(@required_attr), input => [@required_attr, @optional_attr, @mapped_methods], output => ''})}
        die $error if $error;
        if ($def->{method}{'destroy'}){
            $error = Kephra::Base::Class::Method::create_destructor($class, 'destroy', @{$def->{method}{'destroy'}});
        } else { $error = Kephra::Base::Class::Method::create_destructor($class, 'destroy')}
        die $error if $error;

        # Kephra::Base::Class::Method::create_introspector($class, 'state');
        # Kephra::Base::Class::Method::create_reconstructor($class, 'restate');
        # Kephra::Base::Class::Method::create_reproductor($class, 'clone', 'state', 'restate');

        # TODO autogenerated method perl (marshalling) clone
        Kephra::Base::Class::complete($class);
        delete $raw_def{$class};
    }
}
1;

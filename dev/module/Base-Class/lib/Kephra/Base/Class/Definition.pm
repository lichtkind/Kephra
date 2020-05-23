use v5.20;
use warnings;

# serializable data set to build a KBOS class from
#Kephra::Base::Data::Type::Util

package Kephra::Base::Class::Definition;
our $VERSION = 0.2;
use Kephra::Base::Data::Type qw/is_type_known/;
################################################################################
sub new            {        # ~name                     --> .class_def
    return "need only one argument ('name') to create class definition" unless @_ == 2;
    my $store = Kephra::Base::Data::Type::Store->new();
    $store->forbid_shortcuts( @Kephra::Base::Data::Type::Standard::forbidden_shortcuts );
    bless {name => $_[1], types => $store,  method => {state =>{}, restate =>{},}, deps => [] }; # dependencies
}
sub restate        {        # %state                    --> .class_def
    my ($self, $state) = (@_);
    return "restate needs a state (HASH ref) to create new Base::Class::Definition" unless ref $state eq 'HASH';
}
sub state          {        # .class_def                   --> %state
    my $self = (@_);
    my $state = {};
    $state; 
}
################################################################################
sub complete       {        # .class_def                   --> ~errormsg
    my ($self) = (@_);
    return "definition of KBOS class $self->{name} lacks an attribute" unless exists $self->{'attribute'};
    if (exists $self->{'type_def'}){
        
    }
    $self->{'types'}->close();
}
sub is_complete      { not $_[0]->{'types'}->is_open }   # .class_def        --> ?
sub get_dependencies { @{ $_[0]->{'deps'}} }             # ..class_def       --> @~name
################################################################################
sub add_type       {        # .class_def ~name %properties   --> ~errormsg
    my ($self, $type_name, $type_def) = (@_);
    return "class $self->{name} is closed, types can be added" if $self->is_complete;
    return "type definition has to be a hash reference" unless ref $type_def eq 'HASH';
    $type_def->{'name'} = $type_name;
    if (exists $type_def->{'parameter'}) {
        my $param_name = ($type_def->{'parameter'} eq 'HASH') ? $type_def->{'parameter'}{'name'} 
                       : not ref $type_def->{'parameter'} ? $type_def->{'parameter'} : undef;
        return "definition of type $type_name parameter has to have a 'name'" unless defined $param_name and $param_name;

        return "parametric type '$type_name of $param_name' is already defined by this class or standard" 
            if exists $self->{'type_def'}{'param'}{ $type_name }{ $param_name } or is_type_known($type_name, $param_name );
        $self->{'type_def'}{'param'}{ $type_name }{ $param_name } = $type_def;
    } else {
        return "basic type $type_name is already defined in this class or the standard"  if exists $self->{'type_def'}{'basic'}{ $type_name } or is_type_known($type_name);
        $self->{'type_def'}{'basic'}{ $type_name } = $type_def;
    }
}
sub add_method     {        # .class_def ~name %properties       --> ~errormsg
    my ($self, $name, $signature, $code, $keywords) = (@_); # signature code mutli scope type name
    return "class $self->{name} is closed, methods can be added" if $self->is_complete;
    return "method $self->{name}::$name siganture definition has to be an array reference" unless ref $signature eq 'ARRAY';
    return "definition of method $self->{name}::$name need code" unless defined $code;

    return "method $self->{name}::$name is already defined"  if exists $self->{'method'}{$name};
    my ($scope, $kind, $multi);
    my $def = {name => $name, signature => $signature, scope => $scope, kind => $kind};
    if ($multi){ push @{$self->{'method'}{$name}}, $def }  else { $self->{'method'}{$name} = $def }
    '';
}
sub add_attribute  {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_);
    return "class $self->{name} is closed, attributes can be added" if $self->is_complete;
    return "attribute definition in class $self->{name} needs a name as first argument" unless defined $name;
    return "attribute $name of class $self->{name} got no property hash to define itself" unless ref $property eq 'HASH';
    return "attribute $name needs a descriptive 'help' text" unless exists $property->{'help'};
    return "attribute $name needs a to refer to a 'type' or 'class' name" unless exists $property->{'type'} or $property->{'class'};
    $property->{'name'} = $name;
    $self->{'attribute'}{$name} = $property;
}
################################################################################
sub get_types  { $_[0]->{'types'} }   # .class_def                           --> .type
sub get_attribute           {   # .class_def                                 --> %attr_def
    my ($self, $name) = (@_);
}
sub get_method              {   # .class_def                                 --> %method_def
    my ($self, $name) = (@_);
}
################################################################################
sub attribute_names { keys %{$_[0]->{'attribute'}} } # .class_def              --> @~name
sub method_names    { keys %{$_[0]->{'method'}} }    # .class_def            --> @~name
################################################################################
1;

use v5.20;
use warnings;

# serializable data set to build a KBOS class from
#Kephra::Base::Data::Type::Util

package Kephra::Base::Class::Definition;
our $VERSION = 0.2;
use Kephra::Base::Data::Type qw/is_type_known/;
################################################################################
sub new            {        # ~name                     --> .cdef
    return "need only one argument ('name') to create class definition" unless @_ == 2;
    my $store = Kephra::Base::Data::Type::Store->new();
    $store->forbid_shortcuts( @Kephra::Base::Data::Type::Standard::forbidden_shortcuts );
    bless {name => $_[1], complete => 0, type => $store,  attribute => {}, argument=>{},  method => {state =>{}, restate =>{},}, deps => [] }; # dependencies
}
sub restate        {        # %state                    --> .cdef
    my ($self, $state) = (@_);
    return "restate needs a state (HASH ref) to create new Base::Class::Definition" unless ref $state eq 'HASH';
}
sub state          {        # .cdef                     --> %state
    my $self = (@_);
    my $state = {};
    $state; 
}
################################################################################
sub complete       {        # .cdef                     --> ~errormsg
    my $self = (@_);
}
sub is_complete    { $_[0]->{'complete'} }   # .cdef                         --> ?
sub get_dependencies { @{ $_[0]->{'deps'}} } # .cdef                         --> @~name
################################################################################
sub add_type       {        # .cdef ~name %properties   --> ~errormsg
    my ($self, $type_def) = (@_);
    return "type definition has to be a hash reference" unless ref $type_def eq 'HASH';
    return "type definition has to have a 'name'" unless exists $type_def->{'name'};
    my $type_name = $type_def->{'name'};
    if (exists $type_def->{'parameter'}) {
        my $param_name = ($type_def->{'parameter'} eq 'HASH') ? $type_def->{'parameter'}{'name'} 
                       : not ref $type_def->{'parameter'} ? $type_def->{'parameter'} : undef;
        return "definition of type $type_name parameter has to have a 'name'" unless defined $param_name and $param_name;

        return "parametric type $type_name of $param_name"  if exists $self->{'type_def'}{'param'}{ $type_def->{'name'} };
        $self->{'type_def'}{'param'}{ $type_def->{'name'} } = $type_def;
    } else {
        return "basic type $type_name is already defined in this class or the standard"  if exists $self->{'type_def'}{'basic'}{ $type_name } or is_type_known($type_name);
        $self->{'type_def'}{'basic'}{ $type_name } = $type_def;
    }
    return "type definition in class $self->{name} needs a name as first argument" unless defined $name;
    return "type $name of class $self->{name} got no properties to define itself" unless ref $property eq 'HASH';
    $property->{'name'} = $name;
    if (exists $property->{'parameter'}){
        return "definition of class $self->{name} already knows a type '$name' with parameter '$property->{parameter}{name}'" if defined $self->get_type($name, $property->{'parameter'}{'name'});
        $self->{'type'}{'param'}{$name}{ $property->{'parameter'} } = $property;
    } else {
        return "definition of class $self->{name} already knows a type '$name'" if defined $self->get_type($name);
        $self->{'type'}{'basic'}{$name} = $property;
    }
}
sub add_argument   {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_);
    return "argument definition in class $self->{name} needs a name as first argument" unless defined $name;
    return "argument $name of class $self->{name} got no property hash to define itself" unless ref $property eq 'HASH';
    return "argument $name needs a descriptive 'help' text" unless exists $property->{'help'};
    return "argument $name needs a to refer to a 'type' name" unless exists $property->{'type'};
    $property->{'name'} = $name;
    $self->{'argument'}{$name} = $property;
}
sub add_attribute  {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_);
    return "attribute definition in class $self->{name} needs a name as first argument" unless defined $name;
    return "attribute $name of class $self->{name} got no property hash to define itself" unless ref $property eq 'HASH';
    return "attribute $name needs a descriptive 'help' text" unless exists $property->{'help'};
    return "attribute $name needs a to refer to a 'type' or 'class' name" unless exists $property->{'type'} or $property->{'class'};
    $property->{'name'} = $name;
    $self->{'attribute'}{$name} = $property;
}
sub add_method     {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_); # signature code mutli scope type name
    return "method $name of class $self->{name} got no property hash to define itself" unless ref $property eq 'HASH';
    $property->{'name'} = $name;
    $self->{'method'}{$name} = $property;
}
################################################################################
sub get_type                {   # .cdef                                      --> .type
    my ($self, $name, $parameter) = (@_);
    return unless defined $name;
    if (defined $parameter) {
        return $self->{'type'}{'param'}{$name}{$parameter} if exists $self->{'type'}{'param'}{$name} and exists $self->{'type'}{'param'}{$name}{$parameter};
        return Kephra::Base::Data::Type::Standard::get($name, $parameter) if is_type_known($name, $parameter);
    } else {
        return $self->{'type'}{'basic'}{$name} if exists $self->{'type'}{'basic'}{$name};
        return Kephra::Base::Data::Type::Standard::get($name) if is_type_known($name);
    }
}
sub get_argument            {   # .cdef                                      --> %arg_def
    my ($self, $name) = (@_);
}
sub get_attribute           {   # .cdef                                      --> %attr_def
    my ($self, $name) = (@_);
}
sub get_method              {   # .cdef                                      --> %method_def
    my ($self, $name) = (@_);
}
################################################################################
sub list_types                  {   # .cdef - ~kind                          --> @~name
    my ($self, $kind, $name) = (@_);
    $kind = Kephra::Base::Data::Type::Standard::_key_from_kind_($kind);
    return keys %{$self->{'type'}{'simple'}} if $kind eq 'simple';
    if ($kind eq 'param'){
        return keys %{$self->{'type'}{'param'}} unless defined $name;
        return unless exists $self->{'type'}{'param'}{$name};
        return keys %{$self->{'type'}{'param'}{$name}};
    }
}
sub list_arguments { keys %{$_[0]->{'argument'}} }  # .cdef                  --> @~name
    
sub list_attributes         {   # .cdef                 --> @~name
    my ($self, $kind) = (@_);
    keys %{$self->{'attribute'}};
}
sub list_methods            {   # .cdef                 --> @~name
    my ($self, $kind, $scope, $multi) = (@_);
    keys %{$self->{'method'}};
}
################################################################################
1;

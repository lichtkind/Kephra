use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.2;
use Kephra::Base::Data::Type qw/is_type_known/;
################################################################################
sub new            {        # ~name                     --> .cdef
    return "need only one argument ('name') to create class definition" unless @_ == 2;
    bless {name => $_[1], complete => 0, type => {basic => {}, param =>{}}, attribute => {}, argument=>{},  method => {state =>{},restate =>{},}, deps => [] }; # dependencies
}
sub restate        {        # %state                    --> .cdef
    my ($self, $state) = (@_);
    return "restate needs a state (HASH ref) to create new Base::Class::Definition" unless ref $state eq 'HASH';
}
sub state          {        # .cdef                     --> %state
    my $self = (@_);
    $state = {};
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
    my ($self, $name, $property) = (@_);
    return "type definition in class $self->{name} got needs a name as first argument" unless defined $name;
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
    return "argument $name of class $self->{name} got no properties to define itself" unless ref $property eq 'HASH';
    $property->{'name'} = $name;
    $self->{'argument'}{$name} = $property;
}
sub add_attribute  {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_);
    return "attribute $name of class $self->{name} got no properties to define itself" unless ref $property eq 'HASH';
    $property->{'name'} = $name;
    $self->{'attribute'}{$name} = $property;
}
sub add_method     {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_);
    return "method $name of class $self->{name} got no properties to define itself" unless ref $property eq 'HASH';
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

}
sub list_arguments              {   # .cdef                                  --> @~name
    my ($self) = (@_);
}
sub list_attributes         {   # .cdef                 --> @~name
    my ($self, $kind) = (@_);
}
sub list_methods            {   # .cdef                 --> @~name
    my ($self, $kind, $scope, $multi) = (@_);
}
################################################################################
1;

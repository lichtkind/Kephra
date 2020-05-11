use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.2;
use Kephra::Base::Data::Type qw/is_type_known/;
################################################################################
sub new            {        # ~name                     --> .cdef
    return "need only one argument ('name') to create class definition" unless @_ == 2;
    bless {name => $_[1], complete => 0, type => {basic => {}, param =>{}}, attribute => {}, argument=>{},  method => {}, deps => [] }; # dependencies
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
    if (exists $property->{'parameter'}){
        return "class $self->{name} already has a type named '$name' with parameter '$property->{'parameter'}{'name'}'"
            if exists $self->{'type'}{'param'}{ $self->{'name'} }{ $property->{'parameter'}{'name'} };
        return "type '$name' with parameter '$property->{'parameter'}{'name'}' is already defined in class $self->{name}" if is_type_known($name, $property->{'parameter'}{'name'});
    } else {
        return "class $self->{name} already has a type named '$name'" if exists $self->{'type'}{'basic'}{$self->{'name'}};
        return "can not overwrite name of standard type in class  $self->{name} definition" if is_type_known($name);
    }
}
sub add_argument   {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_);
}
sub add_attribute  {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_);
}
sub add_method     {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $property) = (@_);
}
################################################################################
sub get_type                {   # .cdef                     --> .type
    my ($self, $name, $parameter) = (@_);
}
sub get_argument            {   # .cdef                     --> %arg_def
    my ($self, $name) = (@_);
}
sub get_attribute           {   # .cdef                     --> %attr_def
    my ($self, $name) = (@_);
}
sub get_method              {   # .cdef                     --> %method_def
    my ($self, $name) = (@_);
}
################################################################################
sub list_types                  {   # .cdef                 --> @~name
    my ($self, $kind) = (@_);
}
sub list_arguments              {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_data_attributes        {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_delegating_attributes  {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_wrapping_attributes    {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_all_attributes         {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_simple_methods         {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_multi_methods          {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_accessor_methods       {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_constructor_methods    {   # .cdef                 --> @~name
    my ($self) = (@_);
}
sub list_all_methods            {   # .cdef                 --> @~name
    my ($self, $scope) = (@_);
}
################################################################################
1;

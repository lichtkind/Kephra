use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.1;
################################################################################
sub new            {        # ~name                     --> .cdef
    return "need only one argument ('name') to create class definition" unless @_ == 2;
    bless {name => $_[1], complete => 0, type => {}, attribute => {}, argument=>{},  method => {}, deps => {}}; # dependencies
}
sub restate        {        # %state                    --> .cdef
}
sub state          {        # .cdef                     --> %state
}
################################################################################
sub complete       {        # .cdef                     --> ~errormsg
    my $self = (@_);
}
sub is_complete    { $_[0]->{'complete'} }   # .cdef                         --> ?
sub get_dependencies {
}
################################################################################
sub add_type       {        # .cdef ~name %properties   --> ~errormsg
    my ($self, $name, $property) = (@_);
}
sub add_argument   {        # .cdef ~name %properties   --> ~errormsg
    my ($self, $name, $property) = (@_);
}
sub add_attribute  {        # .cdef ~name %properties   --> ~errormsg
    my ($self, $name, $property) = (@_);
}
sub add_method     {        # .cdef ~name %properties   --> ~errormsg
    my ($self, $name, $property) = (@_);
}
################################################################################
sub get_types               {   # .cdef                 --> @%type_def
    my ($self, $name, $property) = (@_);
}
sub get_arguments           {   # .cdef                 --> @%arg_def
    my ($self, $name, $property) = (@_);
}
sub get_data_attributes     {   # .cdef                 --> @%attr_def
    my ($self, $name, $property) = (@_);
}
sub get_wrap_attributes     {   # .cdef                 --> @%attr_def
    my ($self, $name, $property) = (@_);
}
sub get_deleg_attributes    {   # .cdef                 --> @%attr_def
    my ($self, $name, $property) = (@_);
}
sub get_simple_methods      {   # .cdef                 --> @%method_def
    my ($self, $name, $property) = (@_);
}
sub get_multi_methods       {   # .cdef                 --> @%method_def
    my ($self, $name, $property) = (@_);
}
sub get_accessor_methods    {   # .cdef                 --> @%method_def
    my ($self, $name, $property) = (@_);
}
sub get_constructor_methods {   # .cdef                 --> @%method_def
    my ($self, $name, $property) = (@_);
}
################################################################################

1;

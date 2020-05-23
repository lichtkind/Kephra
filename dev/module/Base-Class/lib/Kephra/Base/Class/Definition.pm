use v5.20;
use warnings;

# serializable data set to build a KBOS class from
#Kephra::Base::Data::Type::Util

package Kephra::Base::Class::Definition;
our $VERSION = 0.2;
use Kephra::Base::Data::Type qw/is_type_known/;
################################################################################
sub new            {        # ~class_name                       --> ._
    return "need one argument ('class name') to create class definition" unless @_ == 2;
    my $store = Kephra::Base::Data::Type::Store->new();
    $store->forbid_shortcuts( @Kephra::Base::Data::Type::Standard::forbidden_shortcuts );
    bless {name => $_[1], types => $store,  method => {state =>{}, restate =>{},}, deps => [] }; # dependencies
}
sub restate        {        # %state                      --> ._
    my ($self, $state) = (@_);
    return "restate needs a state (HASH ref) to create new Base::Class::Definition" unless ref $state eq 'HASH';
}
sub state          {        # ._                          --> %state
    my $self = (@_);
    my $state = {};
    $state; 
}
################################################################################
sub complete       {        # ._                          --> ~errormsg
    my ($self) = (@_);
    return "definition of KBOS class $self->{name} lacks an attribute" unless exists $self->{'attribute'};
    if (exists $self->{'type_def'}){
        
    }
    $self->{'types'}->close();
}
sub is_complete      { not $_[0]->{'types'}->is_open }   # ._                --> ?
sub get_dependencies { @{ $_[0]->{'deps'}} }             # ._                --> @~name
################################################################################
sub add_type       {        # ._  ~type_name %type_def                       --> ~errormsg
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
sub add_method     {        # ._  ~name @signature ~code %keywords           --> ~errormsg
    my ($self, $name, $signature, $code, $keyword) = (@_); # signature code mutli scope type name
    my $full_name = "$self->{name}::$name";
    return "class $self->{name} is closed, methods can be added" if $self->is_complete;
    return "siganture definition of method $full_name has to be an array reference - second argument" unless ref $signature eq 'ARRAY';
    return "keywords for method $full_name need to be in a hash (ref) - fourth argument" if ref $keyword ne 'HASH';

    return "signature definition of method $full_name needs to contain at least two counting integer as element 0 ans 1" if @$signature < 2;
    return "amount of required arguments has to be at least zero and less or equal than total amount arguments in signature definition of method $full_name"
        if $signature->[0] < $signature->[1] or $signature->[1] < 0;
    return "amount of total arguments does not fit provided definition of method $full_name signature" if $signature->[0]+2 != @$signature and $signature->[0]+3 != @$signature;
    my $kind = exists $keyword->{'getter'} ? 'getter'
             : exists $keyword->{'setter'} ? 'setter'
             : exists $keyword->{'wrapper'} ? 'wrapper'
             : exists $keyword->{'delegator'} ? 'delegator' : 'simple';
    my $scope = exists $keyword->{'private'} ? 'private'
              : exists $keyword->{'public'} ? 'public'
              : $kind eq 'simple' ? 'public' : 'access';
    my $multi = $keyword->{'multi'};
    delete @$keyword{$kind, $scope, 'multi'};
    my @k = keys %$keyword;
    return "definition of method $full_name contains conflicting keywords @k" if @k;
    if (ref $self->{'method'}{$name} eq 'HASH'){
        return "method $full_name already exists" .(defined $multi ? 'and is not a multi' : '');
    } elsif (ref $self->{'method'}{$name} eq 'ARRAY'){
        return "can not add a none multi (only) method to definition of multi method $full_name" unless defined $multi;
    }
    my $def = {name => $name, signature => $signature, scope => $scope, kind => $kind};
    if (defined $multi){ push @{$self->{'method'}{$name}}, $def } else { $self->{'method'}{$name} = $def }
    '';
}
################################################################################
sub get_types  { $_[0]->{'types'} }   # ._                                   --> .type
sub get_attribute           {         # ._  ~attribute_name                  --> %attr_def
    return unless @_ == 2;
    $_[0]->{'attribute'}{$_[1]};
}
sub get_method              {         # ._  ~method_name                     --> %method_def 
    return unless @_ == 2;
    $_[0]->{'method'}{$_[1]};
}
################################################################################
sub attribute_names { keys %{$_[0]->{'attribute'}} } # .class_def            --> @~name
sub method_names    { keys %{$_[0]->{'method'}} }    # .class_def            --> @~name
################################################################################
1;

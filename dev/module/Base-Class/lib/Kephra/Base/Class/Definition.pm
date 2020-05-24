use v5.20;
use warnings;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.3;
use Kephra::Base::Data::Type qw/is_type_known/;
my $default_methods = {state  => {name => 'state', scope => 'build'}, 
                     restate => {name => 'restate', scope => 'build'}};
################################################################################
sub new            {        # ~class_name                       --> ._
    return "need one argument ('class name') to create class definition" unless @_ == 2;
    my $store = Kephra::Base::Data::Type::Store->new();
    $store->forbid_shortcuts( @Kephra::Base::Data::Type::Standard::forbidden_shortcuts );
    bless {name => $_[1], types => $store,  method => {%$default_methods}, deps => [] }; # dependencies
}
sub restate        {        # %state                      --> ._
    my ($self, $state) = (@_);
    return "restate needs a state (HASH ref) to create new Base::Class::Definition" unless ref $state eq 'HASH';
    bless {};
}
sub state          {        # ._                          --> %state
    my $self = (@_);
    my $state = {types => $self->{'types'}->state, };
    $state; 
}
################################################################################
sub complete       {        # ._                          --> ~errormsg
    my ($self) = (@_);
    return "definition of KBOS class $self->{name} lacks an attribute" unless exists $self->{'attribute'};
    if (exists $self->{'type_def'}){
        while (exists $self->{'type_def'}{'basic'}){
            my @type_def = values %{$self->{'type_def'}{'basic'}};
            for my $type_def (@type_def){
                Kephra::Base::Data::Type::Util::substitude_names($type_def, $self->{'types'});
                unless (Kephra::Base::Data::Type::Util::can_substitude_names($type_def)){
                    my $type = Kephra::Base::Data::Type::Basic->new($type_def);
                    return "error in definition of the types of class $self->{name}: $type" unless ref $type;
                    $self->{'types'}->add_type($type, $type_def->{'shortcut'});
                    delete $self->{'type_def'}{'basic'}{ $type_def->{'name'} };
            }   }
            my $count = keys %{$self->{'type_def'}{'basic'}};
            return "basic type definitions in class $self->{name} have unresolvable dependencies" if $count == @type_def;
            delete $self->{'type_def'}{'basic'} unless $count; 
        }
        while (exists $self->{'type_def'}{'param'}){
            my $evaled = 0;
            for my $group_def (values %{$self->{'type_def'}{'param'}}){
                for my $type_def (values %$group_def){
                    Kephra::Base::Data::Type::Util::substitude_names($type_def, $self->{'types'});
                    unless (Kephra::Base::Data::Type::Util::can_substitude_names($type_def)){
                         my $type = Kephra::Base::Data::Type::Parametric->new($type_def);
                         return "error in definition of the types of class $self->{name}: $type" unless ref $type;
                         $self->{'types'}->add_type($type, $type_def->{'shortcut'});
                         delete $group_def->{ $type_def->{'parameter'}{'name'} };
                         delete $self->{'type_def'}{'param'}{ $type_def->{'name'} } unless keys %{$self->{'type_def'}{'param'}{ $type_def->{'name'} }};
                         $evaled++;
            }   }   }
            return "parametric type definitions in class $self->{name} have unresolvable dependencies" unless $evaled;
            delete $self->{'type_def'}{'param'} unless keys %{$self->{'type_def'}{'param'}}; 
    }   }
    $self->{'types'}->close();
}
sub is_complete      { not $_[0]->{'types'}->is_open }   # ._                --> ?
sub get_dependencies { @{ $_[0]->{'deps'}} }             # ._                --> @~name
################################################################################
sub add_type       {        # ._  ~type_name %type_def                       --> ~errormsg
    my ($self, $type_name, $type_def) = (@_);
    return "class $self->{name} is closed, types can be added" if $self->is_complete;
    return "type definition in class $self->{name} needs a name as first argument" unless defined $type_name and $type_name;
    return "type definition has to be a hash reference" unless ref $type_def eq 'HASH';
    $type_def->{'name'} = $type_name;
    Kephra::Base::Data::Type::Util::substitude_names($type_def, Kephra::Base::Data::Type::standard);
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
    }'';
}
sub add_attribute  {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $attr_def) = (@_);
    return "class $self->{name} is closed, attributes can be added" if $self->is_complete;
    return "attribute definition in class $self->{name} needs a name as first argument" unless defined $name and $name;
    my $error_start = "attribute $name of class $self->{name}";
    return "$error_start got no property hash to define itself" unless ref $attr_def eq 'HASH';
    return "$error_start needs a descriptive 'help' text" unless exists $attr_def->{'help'};
    return "$error_start has no associated getter method" if exists $attr_def->{'set'} and not exists $attr_def->{'get'};
    my $kind = (exists $attr_def->{'get'}) + (exists $attr_def->{'wrap'}) + (exists $attr_def->{'delegate'});
    my $build = (exists $attr_def->{'build'}) + (exists $attr_def->{'build_lazy'}) + (exists $attr_def->{'init'}) + (exists $attr_def->{'init_lazy'});
    return "$error_start needs an associated getter, delegator or wrapper method" if $kind == 0;
    return "$error_start can only have getter or delegator or wrapper" if $kind > 1;
    if (exists $attr_def->{'get'}){
        return "$error_start needs a to refer to a data 'type'" unless exists $attr_def->{'type'};
        return "$error_start can only have one 'init' or 'init_lazy' or 'build' or 'build_lazy' property" if $build > 1;
    } else {
        return "$error_start needs a to refer to a 'class'" unless exists $attr_def->{'class'};
        return "$error_start can only have one 'build' or 'build_lazy' property" if $build > 1;
    }
    $attr_def->{'name'} = $name;
    $self->{'attribute'}{$name} = $attr_def;
    '';
}
sub add_method     {        # ._  ~name @signature ~code %keywords           --> ~errormsg
    my ($self, $name, $signature, $code, $keyword) = (@_); # signature code mutli scope type name
    my $full_name = "$self->{name}::$name";
    return "class $self->{name} is closed, methods can be added" if $self->is_complete;
    return "siganture definition of method $full_name has to be an array reference - second argument" unless ref $signature eq 'ARRAY';
    return "keywords for method $full_name need to be in a hash (ref) - fourth argument" if ref $keyword ne 'HASH';
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
sub get_types  { $_[0]->{'types'} }   # ._                                   --> .type_store
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

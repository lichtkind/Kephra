use v5.20;
use warnings;
use List::Util;

# serializable data set to build a KBOS class from

package Kephra::Base::Class::Definition;
our $VERSION = 0.7;
use Kephra::Base::Data qw/clone_data/;
use Kephra::Base::Class::Definition::Scope;
use Kephra::Base::Class::Definition::Attribute;
use Kephra::Base::Class::Definition::Method;
use Kephra::Base::Class::Definition::Store;
use List::Util qw/reduce/;

my $default_methods = {state  => {name => 'state', scope => 'build'}, 
                     restate => {name => 'restate', scope => 'build'}};

sub new            {        # ~class_name                       --> ._
    return "need one argument ('class name') to create class definition" unless @_ == 2;
    return "class name has to start with an upper case letter" unless reduce {$a && $b} map {/^[A-Z]/} split /::/, $_[1];
    return "class name can only contain word character" unless $_[1] =~ /^[\w:]+$/;
    my $type_store = Kephra::Base::Data::Type::Store->new();
    $type_store->forbid_shortcuts( @Kephra::Base::Data::Type::Standard::forbidden_shortcuts );
    bless {name => $_[1], dependencies => [], requirements => [],
           types => $type_store,  attribute => {}, method => {%$default_methods} };
}

sub add_type {
    my ($self, $type_def) = @_;
}
sub get_type {
}

sub add_attribute {
    my ($self, $attr_def) = @_;

}
sub get_attribute {

}

sub add_method    {
    my ($self, $method_def) = @_;

}
sub get_method    {

}

sub get_type         {                             # ._                      --> .type 
    my $self = shift;
    Kephra::Base::Data::Type::standard->get_type(@_) // $self->{'types'}->get_type(@_);
}
sub attribute_names { sort keys (%{$_[0]->{'attribute'}})  }   # ._    --> @~attrnames
sub method_names    { keys %{$_[0]->{'method'}} }       # ._           --> @~method_def.~name
sub get_dependencies { @{ $_[0]->{'dependencies'}} } # ._              --> @~depnames
sub get_requirements { @{ $_[0]->{'requirements'}} } # ._              --> @~reqnames

sub complete    {
    my $self = shift;
    $self->{'types'}->close();
}
sub is_complete      { $_[0]->{'types'}->is_open ? 0 : 1 }     # ._          --> ?

################################################################################
sub state         {      # ._                          --> %state

}

sub restate       {      # %state                      --> ._

}


1;

__END__


################################################################################
sub restate        {        # %state                      --> ._
    my ($self, $state) = (@_);
    return "restate needs a state (HASH ref with types, attribtutes and methods) to create new Base::Class::Definition" 
        unless ref $state eq 'HASH' and exists $state->{'types'} and exists $state->{'method'} and exists $state->{'attribute'};
    $state->{'types'} = Kephra::Base::Data::Type::Store->restate($state->{'types'});
    bless $state;
}
sub state          {        # ._                          --> %state
    my $self = (@_);
    { name => $self->{'name'}, types => $self->{'types'}->state,
      dependencies => {%{$self->{'dependencies'}}}, requirements => {%{$self->{'requirements'}}},
      method=> clone_data($self->{'method'}), attribute=> clone_data($self->{'attribute'}),   };
}
################################################################################
sub get_attribute { $_[0]->{'attribute'}{$_[1]}; } # ._  ~attribute_name     --> %attr_def
sub get_method   {  $_[0]->{'method'}{$_[1]}; }    # ._  ~method_name        --> %method_def 
################################################################################
sub get_type         {                             # ._                      --> .type 
    my $self = shift;
    Kephra::Base::Data::Type::standard->get_type(@_) // $self->{'types'}->get_type(@_);
}
sub method_names    { keys %{$_[0]->{'method'}} }       # ._          --> @~method_def.~name
sub attribute_names { sort keys (%{$_[0]->{'attribute'}})  }   # ._          --> @~attr_def.~name
sub get_dependencies { sort keys %{ $_[0]->{'dependencies'}} } # ._          --> @~attr_def.~class
sub get_requirements { sort keys (%{ $_[0]->{'requirements'}}) } # ._        --> @~attr_def.~class
sub is_complete      { $_[0]->{'types'}->is_open ? 0 : 1 }     # ._          --> ?
################################################################################
sub complete       {        # ._                          --> ~errormsg
    my ($self) = (@_);
    return "class $self->{name} is completed" if $self->is_complete;
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
        }
        delete $self->{'type_def'};
    }
    my $std_types = Kephra::Base::Data::Type::standard;
    my %special = {};
    for my $method (values %{$self->{'method'}}){
        for my $method_def ((ref $method eq 'ARRAY') ? @$method : $method){
            my $sep_count = 0;
            my $ret_start = 0;
            my %arg_type;
            $special{'constructor'}++ if $method_def->{'kind'} eq 'constructor';
            $special{'destructor'}++ if $method_def->{'kind'} eq 'destructor';
            for my $i (0 .. $#{$method_def->{'signature'}}){
                return "signature definition of method $self->{name}::$method_def->{name} has too many separators" if $sep_count > 2;
                my $arg = $method_def->{'signature'}[$i];
                $ret_start = $i if $sep_count == 1 and not defined $arg;
                $sep_count++, next unless defined $arg;
                my $error_stem = ($sep_count == 2) ? ($i-$ret_start)."st return value in signature definition of method $self->{name}::$method_def->{name}" 
                                               : "$i st argument in signature definition of method $self->{name}::$method_def->{name}";
                if ($sep_count == 2){
                    my $name = 'return_value_'.($i-$ret_start);
                    push @$arg, $name if ref $arg eq 'ARRAY';
                    $method_def->{'signature'}[$i] = $arg = [$arg, $name] unless ref $arg;
                }
                unless (ref $arg){
                    my $sigil = substr($arg, 0, 1);
                    next if $sigil =~ /[a-z]/;
                    return "$error_stem has no name" if length $arg < 2;
                    my $twigil = substr($arg, 1, 1);
                    if ($twigil =~ /[a-z]/)  { $method_def->{'signature'}[$i] = $arg = [$sigil, substr( $arg,1)] }
                    else {                     $method_def->{'signature'}[$i] = $arg = [$sigil, $twigil, substr($arg, 2)];
                        return "$error_stem has no name" if length $arg == 2;
                    }
                }
                return "malformed data of $error_stem, it has to be a string or an array reference" if ref $arg ne 'ARRAY';
                if (@$arg == 2){
                    my $type_name = $arg->[0];
                    return "$error_stem, has zero length type name" unless defined $type_name and $type_name;
                    my $sigil = substr($type_name, 0, 1);
                    if ($sigil !~ /[a-z]/) {
                        if (length $type_name > 1){
                            $method_def->{'signature'}[$i] = $arg = [$sigil, substr( $type_name, 1 )]
                        } else {
                            $arg->[0] = $std_types->resolve_shortcut('basic', $sigil) // $self->{'types'}->resolve_shortcut('basic', $sigil);
                            return "$error_stem contains the unknown type sigil '$sigil'" unless defined $arg->[0];
                }   }   }
                if (@$arg == 2){
                    my $type_name = $arg->[0];
                    return "$error_stem contains the unknown type '$type_name'" unless $std_types->is_type_known($type_name) or $self->{'types'}->is_type_known($type_name);
                    $arg_type{$arg->[1]} = $arg->[0] if $sep_count < 2;
                } elsif (@$arg == 3){
                    my ($sigil, $twigil) = @$arg;
                    if (length $sigil == 1 and $sigil !~ /[a-z]/){
                        $arg->[0] = $std_types->resolve_shortcut('param', $sigil) // $self->{'types'}->resolve_shortcut('param', $sigil);
                        return "$error_stem contains the unknown parametric type sigil '$sigil'" unless defined $arg->[0];
                    }
                    if (length $twigil == 1 and $twigil !~ /[a-z]/){
                        $arg->[1] = $std_types->resolve_shortcut('basic', $twigil) // $self->{'types'}->resolve_shortcut('basic', $twigil);
                        return "$error_stem contains the unknown basic type twigil '$twigil'" unless defined $arg->[1];
                    }
                    return "$error_stem contains the unknown type '$arg->[0]' of '$arg->[1]'" unless $std_types->is_type_known(@$arg) or $self->{'types'}->is_type_known(@$arg);
                } elsif (@$arg == 4){
                    my ($type_name, $kind, $relator_name, $param_name) = @$arg;
                    if (substr( $kind, 0, 4) eq 'attr'){
                        return "$error_stem refers not existing attribute '$arg->[2]'" unless exists $self->{'attribute'}{$arg->[2]};
                        return "$error_stem refers to a typeless attribute '$arg->[2]'"unless exists $self->{'attribute'}{$arg->[2]}{'type'};
                        $param_name = $self->{'attribute'}{$arg->[2]}{'type'};
                    } elsif (substr( $kind, 0, 3) eq 'arg'){
                        return "$error_stem does not refer to an existing basic typed argument '$arg->[2]'" unless exists $arg_type{$arg->[2]};
                        $param_name = $arg_type{$arg->[2]};
                    } else {return "$error_stem relates to something else than an attribute or argument"}
                    return "$error_stem contains the unknown type '$arg->[0] of $arg->[1] $arg->[2], which is of type $param_name, but there is not type '$arg->[0] of $param_name'"
                        unless $std_types->is_type_known($arg->[0], $param_name) or $self->{'types'}->is_type_known($arg->[0], $arg->[1]);
                } else {return "malformed $error_stem - no or too many entries (max. is 4)" if ref $arg ne 'ARRAY' }
            }
        }
    }
    return "class $self->{name} has no constructor but uses 'new' as method name" if exists $self->{'method'}{'new'} and not exists $special{'constructor'};
    return "class $self->{name} has no destructor but uses 'demolish' as method name" if exists $self->{'method'}{'demolish'} and not exists $special{'destructor'};
    $self->{'method'}{'new'}      = {name=>'new',     kind=>'constructor', scope => 'public'} unless exists $special{'constructor'};
    $self->{'method'}{'demolish'} = {name=>'demolish', kind=>'destructor', scope => 'public'} unless exists $special{'destructor'};

    for my $attr_def (@{$self->{'attribute'}}){
        if (exists $attr_def->{'type'}){
            my $type = $std_types->get_type( $attr_def->{'type'} ) // $self->{'types'}->get_type( $attr_def->{'type'} );
            return "data attribute $attr_def->{name} of class $self->{name} has an unknown type" unless ref $type;
            return "data attribute $attr_def->{name} of class $self->{name} has the initial value '$attr_def->{init}' that does not fit its type ".$type->get_name
                if exists $attr_def->{'init'} and $type->check( $attr_def->{'init'} );
            return "data attribute $attr_def->{name} of class $self->{name} has the initial value '$attr_def->{init}' that does not fit its type ".$type->get_name
                if exists $attr_def->{'init_lazy'} and $type->check( $attr_def->{'init_lazy'} );
            my $error = $self->_missing_method_($attr_def->{'get'}) or $self->_missing_method_($attr_def->{'set'});
            return "definition of data attribute $attr_def->{name} of class $self->{name} has issue: $error" if $error;
        } elsif (exists $attr_def->{'delegate'}){
            my $error = $self->_missing_method_($attr_def->{'delegate'});
            return "definition of delegating attribute $attr_def->{name} of class $self->{name} has issue: $error" if $error;
            $self->{'dependencies'}{ $attr_def->{'class'} }++;
        } else {
            my $error = $self->_missing_method_($attr_def->{'wrap'});
            return "definition of wrapping attribute $attr_def->{name} of class $self->{name} has issue: $error" if $error;
            $self->{'requirements'}{ ($attr_def->{'require'} eq 1 ? $attr_def->{'class'} : $attr_def->{'require'}) }++;
        }
    }
    $self->{'types'}->close();
}
sub _missing_method_ {
    my ($self, $attr_methods) = (@_);
    return '' unless defined $attr_methods;
    return 'no methods defined' unless $attr_methods;
    my $ref = ref $attr_methods;
    return $self->_check_method_name_($attr_methods) unless $ref;
    if ($ref eq 'ARRAY'){     for (@$attr_methods){      my $error = $self->_check_method_name_($_);  return $error if $error; } }
    elsif ($ref eq 'HASH'){   for (keys %$attr_methods){ my $error = $self->_check_method_name_($_);  return $error if $error; } }
    else {return 'malformed property, methods can only be provided in string, array or hash'}
    '';
}
sub _check_method_name_{
    my ($self, $name) = (@_);
    if (substr($name, 0, 1) eq '-'){
        $name = substr($name, 1);
        return "method $name is not an identifier (beginning with lower case letter + digits + _)" unless _is_identifier_($name);
        return "method $name already exists and can not be generated" if exists $self->{'method'}{$name};
    } else { return "method $name was not defined" unless exists $self->{'method'}{$name} }
    '';
}
sub _is_identifier_ {
    return 0 unless $_[0];
    return 0 if $_[0] =~ /[^a-z_0-9]/;
    ($_[0] =~ /^[a-z]/) ? 1 : 0;
}

################################################################################
sub add_type       {        # ._  ~type_name %type_def                       --> ~errormsg
    my ($self, $type_name, $type_def) = (@_);
    return "class $self->{name} is completed, types can be added" if $self->is_complete;
    return "type definition in class $self->{name} needs a name as first argument" unless defined $type_name and $type_name;
    return "type definition has to be a hash reference" unless ref $type_def eq 'HASH';
    $type_def->{'name'} = $type_name;
    my $std_types = Kephra::Base::Data::Type::standard;
    Kephra::Base::Data::Type::Util::substitude_names($type_def, $std_types);
    if (exists $type_def->{'parameter'}) {
        my $param_name = ($type_def->{'parameter'} eq 'HASH') ? $type_def->{'parameter'}{'name'} 
                       : not ref $type_def->{'parameter'} ? $type_def->{'parameter'} : undef;
        return "definition of type $type_name parameter has to have a 'name'" unless defined $param_name and $param_name;

        return "parametric type '$type_name of $param_name' is already defined by this class or standard" 
            if exists $self->{'type_def'}{'param'}{ $type_name }{ $param_name } or $std_types->is_type_known($type_name, $param_name );
        return "sigil $type_def->{shortcut} of parametric type $type_name is not allowed to overwrite standard type sigil "
            if exists $type_def->{'shortcut'} and defined $std_types->resolve_shortcut('param', $type_def->{'shortcut'});
        $self->{'type_def'}{'param'}{ $type_name }{ $param_name } = $type_def;
    } else {
        return "basic type $type_name is already defined in this class or the standard"  if exists $self->{'type_def'}{'basic'}{ $type_name } or $std_types->is_type_known($type_name);
        return "sigil $type_def->{shortcut} of basic type $type_name is not allowed to overwrite standard type sigil "
            if exists $type_def->{'shortcut'} and defined $std_types->resolve_shortcut('basic', $type_def->{'shortcut'});
        $self->{'type_def'}{'basic'}{ $type_name } = $type_def;
    }'';
}
sub add_attribute  {        # .cdef ~name %properties       --> ~errormsg
    my ($self, $name, $attr_def) = (@_);
    return "class $self->{name} is completed, attributes can be added" if $self->is_complete;
    my $attr = Kephra::Base::Class::Definition::Attribute->new($name, $attr_def);
    return "class $self->{name} $attr" unless ref $attr;
    $self->{'attribute'}{$name} = $attr;
    '';
}
sub add_method     {        # ._  ~name @signature ~code %keywords           --> ~errormsg
    my ($self, $name, $signature, $code, $keyword) = (@_); # signature code mutli scope type name
    return "class $self->{name} is completed, methods can be added" if $self->is_complete;
    return "method definition in class $self->{name} needs a name as first argument" unless defined $name and $name;
    return "method name $name is not an identifier (beginning with lower case letter + digits + _)" unless _is_identifier_($name);
    my $full_name = "$self->{name}::$name";
    return "siganture definition of method $full_name has to be an array reference - second argument" unless ref $signature eq 'ARRAY';
    return "keywords for method $full_name need to be in a hash (ref) - fourth argument" if ref $keyword ne 'HASH';
    my $kind = exists $keyword->{'constructor'} ? 'constructor'
             : exists $keyword->{'destructor'} ? 'destructor'
             : exists $keyword->{'getter'} ? 'getter'
             : exists $keyword->{'setter'} ? 'setter'
             : exists $keyword->{'wrapper'} ? 'wrapper'
             : exists $keyword->{'delegator'} ? 'delegator' : 'regular';
    my $scope = exists $keyword->{'private'} ? 'private'
              : exists $keyword->{'public'} ? 'public'
              : ($kind eq 'regular' or $kind eq 'constructor'  or $kind eq 'destructor' ) ? 'public' : 'access';
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
1;

# Kephra::Base::Data::Type::standard->check_basic_type('identifier', $name);
# return "attribute definition needs an identifier (a-zA-Z0-9_) as first argument" 
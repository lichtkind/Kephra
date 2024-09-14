use v5.20;
use warnings;

# validate and serialize attribute definition
# 0102_Base-Class-Definition-Attribute.t

package Kephra::Base::Class::Definition::Attribute;
our $VERSION = 2.0;
use Kephra::Base::Class::Definition::Scope;

sub new { # ~pkg %properties ~name  --> ._| ~errormsg
    my ($pkg, $name, $attr_def) = (@_);
    return 'need two argumens: attribte definition (HASH ref) and name (identifier)' unless defined $attr_def;
    my $error_start = "definition of class attribute '$name'";
    return $error_start.' has to be a HASH reference' unless ref $attr_def eq 'HASH';
    return $error_start.' needs a descriptive text of more than 10 character under key "help"'
        unless exists $attr_def->{'help'} and not ref $attr_def->{'help'} and length $attr_def->{'help'} > 10;

    $attr_def = {%$attr_def}; # shallow clone data to keep input untouched
    my $self = { help => delete $attr_def->{'help'}, 
                 build => '', state => '', restate => '', lazy => 0, setter_name => '', setter_scope => ''};
    $attr_def->{'kind'} = 'native' unless exists $attr_def->{'kind'}; # default to native kind of attribute

    my $kind = $self->{'kind'} = delete $attr_def->{'kind'};
    if    ($kind eq 'native')    {
        return $error_start." misses under key 'type' a name of an existing type" 
            unless exists $attr_def->{'type'} and not ref $attr_def->{'type'};
        $self->{'type_class'} = delete $attr_def->{'type'};
        if (defined $attr_def->{'setter'}){
            if (not ref $attr_def->{'setter'}){
                my $scope = delete $attr_def->{'setter'};
                return "$error_start property 'setter' demands unknown scope '$scope' ".
                       "instead of build (default), access, private, public" 
                    unless Kephra::Base::Class::Definition::Scope::is_method_scope( $scope );
                $self->{'setter_name'} = $name;
                $self->{'setter_scope'} = $scope;
            } elsif (ref $attr_def->{'setter'} eq 'HASH'){
                return "$error_start property 'setter' has too many keys" if keys %{$attr_def->{'setter'}} > 1;
                my ($name) = keys %{$attr_def->{'setter'}};
                my $scope = $attr_def->{'setter'}{$name};
                return "$error_start property 'setter' demands unknown scope '$scope' ".
                       "instead of build (default), access, private, public" 
                    unless Kephra::Base::Class::Definition::Scope::is_method_scope( $scope );
                $self->{'setter_name'} = $name;
                $self->{'setter_scope'} = $scope;
                delete $attr_def->{'setter'}
            } else { return "$error_start property 'setter' has to be a name string or hash: {name => 'scope'}"}
        } else {
            $self->{'setter_name'} = $name;
            $self->{'setter_scope'} = 'build';
        }

    } elsif ($kind eq 'delegating'){
        return $error_start.' can as a delegating attribute not have code under keys "state" or "restate"'
            if exists $attr_def->{'state'} or exists $attr_def->{'restate'};
        return $error_start.' needs as a delegating attribute under key "class" a name of an existing KBOS class' 
            unless exists $attr_def->{'class'} and not ref $attr_def->{'class'};
        $self->{'type_class'} = delete $attr_def->{'class'};
        $attr_def->{'build'} = delete $attr_def->{'build_args'} if exists $attr_def->{'build_args'};
        $attr_def->{'build_lazy'} = delete $attr_def->{'build_args_lazy'} if exists $attr_def->{'build_args_lazy'};

    } elsif ($kind eq 'wrapping')  {
        return $error_start.' needs as a wrapping attribut under key "state" and "restate" code to serialize the none KBOS object'
            unless exists $attr_def->{'state'} and exists $attr_def->{'restate'};
        return $error_start.' needs under key "require" a name (or array ref to list of names) '
              .'of required modules to load none KBOS class' 
            unless exists $attr_def->{'require'} 
            and (not ref $attr_def->{'require'} or ref $attr_def->{'require'} eq 'ARRAY');
        $self->{'type_class'} = delete $attr_def->{'require'};
        return $error_start.' needs as a wrapping attribute code to build a none KBOS class under the key "build" or "build_lazy".'
            unless (exists $attr_def->{'build'} and not ref $attr_def->{'build'})
                or (exists $attr_def->{'build_lazy'} and not ref $attr_def->{'build_lazy'});
    } else {return "$error_start lacks valid attribute 'kind', has to be: 'native' or 'delegating' or 'wrapping'"}

    if (defined $attr_def->{'getter'}){
        if (not ref $attr_def->{'getter'}){
            my $scope = delete $attr_def->{'getter'};
            return "$error_start property 'getter' demands unknown scope '$scope' ".
                   "instead of build, access (default), private, public" 
                unless Kephra::Base::Class::Definition::Scope::is_method_scope( $scope );
            $self->{'getter_name'} = $name;
            $self->{'getter_scope'} = $scope;
        } elsif (ref $attr_def->{'getter'} eq 'HASH'){
            return "$error_start property 'getter' has too many keys" if keys %{$attr_def->{'getter'}} > 1;
            my ($name) = keys %{$attr_def->{'getter'}};
            my $scope = $attr_def->{'getter'}{$name};
            return "$error_start property 'getter' demands unknown scope '$scope' ".
                    "instead of build, access (default), private, public" 
                unless Kephra::Base::Class::Definition::Scope::is_method_scope( $scope );
            $self->{'getter_name'} = $name;
            $self->{'getter_scope'} = $scope;
            delete $attr_def->{'getter'}
        } else { return "$error_start property 'getter' has to be a name string or hash: {name => 'scope'}"}
    } else {
        $self->{'getter_name'} = $name;
        $self->{'getter_scope'} = 'access';
    }

    $self->{'lazy'}  = 1 if defined $attr_def->{'build_lazy'} and $attr_def->{'build_lazy'};
    for (qw/state restate build/) {
        $self->{$_} = delete $attr_def->{$_} if defined $attr_def->{$_};
    }
    $self->{'build'} = delete $attr_def->{'build_lazy'} if defined $attr_def->{'build_lazy'};

    return "$error_start contains not needed keys: ".join( ' ', (keys %$attr_def)).", for attribute kind $kind" if %$attr_def;
    bless $self;
}

################################################################################
sub state       { $_[0] }
sub restate     { bless shift }
################################################################################
sub kind        {$_[0]->{'kind'}}
sub help        {$_[0]->{'help'}}
sub type        {$_[0]->{'type_class'}}
sub class       {$_[0]->{'type_class'}}
sub require     {$_[0]->{'type_class'}}
sub build_code  {$_[0]->{'build'}}      # can be just value different from type default
sub state_code  {$_[0]->{'state'}}
sub restate_code{$_[0]->{'restate'}}
sub build_args  {$_[0]->{'build'}}
sub is_lazy     {$_[0]->{'lazy'}}
sub getter_name {$_[0]->{'getter_name'}}
sub getter_scope{$_[0]->{'getter_scope'}}
sub setter_name {$_[0]->{'setter_name'}}
sub setter_scope{$_[0]->{'setter_scope'}}

1;

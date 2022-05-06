use v5.20;
use warnings;

# check data structure holding a definition of a native data holding KBOS attribute
# 0102_Base-Class-Definition-Attribute-Native.t

package Kephra::Base::Class::Definition::Attribute::Native;
our $VERSION = 1.4;
our @ISA = 'Kephra::Base::Class::Definition::Attribute';

sub new {        # ~pkg %attr_def            --> ._ | ~errormsg
    my ($pkg, $attr_def) = (@_);
    my $error_start = "definition of native class attribute  ";
    my $self = {build => '', lazy => 0};
    return "need a property hash to create a native data attribute definition" unless ref $attr_def eq 'HASH';
    for (qw/name help type/) {
        return "$error_start lacks '$_' property" unless exists $attr_def->{ $_ };
        return "$error_start property '$_' can not be a reference"  if ref $attr_def->{$_};
        return "$error_start property '$_' can not be empty"  unless $attr_def->{$_};
        $error_start .= $attr_def->{'name'} if $_ eq 'name';
        $self->{$_} = delete $attr_def->{$_};
    }
    $self->{'kind'} = 'native';
    $self->{'type_class'} = delete $self->{'type'};
    $self->{'lazy'}  = 1 if defined $attr_def->{'lazy_build'} and $attr_def->{'lazy_build'};
    $self->{'build'} = delete $attr_def->{'build'} if defined $attr_def->{'build'};
    $self->{'build'} = delete $attr_def->{'lazy_build'} if defined $attr_def->{'lazy_build'};

    if (defined $attr_def->{'getter'}){
        if (not ref $attr_def->{'getter'}){
            my $scope = delete $attr_def->{'getter'};
            return "$error_start property 'getter' demands unknown scope '$scope' ".
                   "instead of build, access (default), private, public" 
                unless Kephra::Base::Class::Definition::Scope::is_method_scope( $scope );
            $self->{'getter_name'} = $self->{'name'};
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
        $self->{'getter_name'} = $self->{'name'};
        $self->{'getter_scope'} = 'access';
    }
    if (defined $attr_def->{'setter'}){
        if (not ref $attr_def->{'setter'}){
            my $scope = delete $attr_def->{'setter'};
            return "$error_start property 'setter' demands unknown scope '$scope' ".
                   "instead of build (default), access, private, public" 
                unless Kephra::Base::Class::Definition::Scope::is_method_scope( $scope );
            $self->{'setter_name'} = $self->{'name'};
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
        $self->{'setter_name'} = $self->{'name'};
        $self->{'setter_scope'} = 'build';
    }
    return "$error_start contains unknown keys: ".join( ' ', (keys %$attr_def)) if %$attr_def;
    bless $self;
}

1;
use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Attribute::Data;
our $VERSION = 1.0;
################################################################################
sub new {        # ~pkg %attr_def            --> ._ | ~errormsg
    my ($pkg, $attr_def) = (@_);
    my $self = {methods => [], auto => {}, lazy => 0};
    return "need a property hash to create a data attribute definition" unless ref $attr_def eq 'HASH';
    my $error_start = 'data attribute ';
    $error_start .= $attr_def->{name} if exists $attr_def->{name};
    for (qw/name help type/) {
        return "$error_start lacks property '$_'" unless exists $attr_def->{$_};
        $self->{$_} = delete $attr_def->{$_};
    }
    if    (exists $attr_def->{'init'})      {$self->{'init'}  = delete $attr_def->{'init'} }
    elsif (exists $attr_def->{'build'})     {$self->{'build'} = delete $attr_def->{'build'} }
    elsif (exists $attr_def->{'lazy_build'}){$self->{'build'} = delete $attr_def->{'lazy_build'}; $self->{'lazy'} = 1; }

    return "$error_start lacks property 'get' or 'auto_get'" unless exists $attr_def->{'get'} or exists $attr_def->{'auto_get'};
    return "$error_start property 'get' has to be string with valid getter method name or an arry of such names"
        if exists $attr_def->{'get'} and ref $attr_def->{'get'} and ref $attr_def->{'get'} ne 'ARRAY';
    return "$error_start property 'set' has to be string with valid setter method name or an arry of such names"
        if exists $attr_def->{'set'} and ref $attr_def->{'set'} and ref $attr_def->{'set'} ne 'ARRAY';
    push @{$self->{'methods'}}, @{delete $attr_def->{'get'}} if ref $attr_def->{'get'} eq 'ARRAY';
    push @{$self->{'methods'}},   delete $attr_def->{'get'}  if not ref $attr_def->{'get'} and exists $attr_def->{'get'};
    push @{$self->{'methods'}}, @{delete $attr_def->{'set'}} if ref $attr_def->{'set'} eq 'ARRAY';
    push @{$self->{'methods'}},   delete $attr_def->{'set'}  if not ref $attr_def->{'set'} and exists $attr_def->{'set'};

    return "$error_start property 'auto_get' has to be defined by an hash: {method => scope}" if exists $attr_def->{'auto_get'} and ref $attr_def->{'auto_get'} ne 'HASH';
    $self->{'auto'} = {%{ delete $attr_def->{'auto_get'}}} if ref $attr_def->{'auto_get'} eq 'HASH';
    if (ref $attr_def->{'auto_set'} eq 'HASH'){
        $self->{'auto'}{$_} = [$self->{'auto'}{$_} , $attr_def->{'auto_set'}{$_}] for keys %{$attr_def->{'auto_set'}};
        delete $attr_def->{'auto_set'};
    }
    for (keys %$attr_def){ return "$error_start has the illegal, malformed or effectless property '$_'"  }
    bless $self;
}

sub check_type {    # ._       --> ~errormsg
    my $self = shift;
    for my $store (@_){
        next unless ref $store eq 'Kephra::Base::Data::Type::Store';
        if ($store->is_type_known( $self->{'type'} )){
            $self->{'init'} = $store->get_type( $self->{'type'} )->get_default_value() if not exists $self->{'init'} and not exists $self->{'build'};
            return '';
        }
    }
    return "data attribute $self->{name} has an unknown type: '$self->{'type'}'";
}
################################################################################
sub state   { {%{$_[0]}} }
sub restate { bless shift}
################################################################################
sub get_kind  {'data'}
sub get_help  {$_[0]->{'help'}}
sub get_type  {$_[0]->{'type'}}
sub get_init  {$_[0]->{'init'}}
sub get_build {$_[0]->{'build'}}
sub is_lazy   {$_[0]->{'lazy'}}
sub accessor_names  {@{ $_[0]->{'methods'}} }
sub auto_accessors  {$_[0]->{'auto'}} # name => scope | [getscope, setscope]
sub get_dependency  { undef }
sub get_requirement { undef }

1;

use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Attribute::Data;
our $VERSION = 0.1;
################################################################################
sub new {        # ~pkg %attr_def            --> ._ | ~errormsg
    my ($pkg, $attr_def) = (@_);
    return "need a property hash to create a data attribute definition" unless ref $attr_def eq 'HASH';
    my $error_start = ("data attribute $attr_def->{name}");
    my $self = {methods => [], auto => {}};
    for (qw/name help type/) {
        return "$error_start lacks property '$_'" unless exists $attr_def->{$_};
        $self->{$_} = delete $attr_def->{$_};
    }
    $self->{'lazy'} = 0;
    if    (exists $attr_def->{'init'})      {$self->{'init'}  = delete $attr_def->{'init'} }
    elsif (exists $attr_def->{'build'})     {$self->{'build'} = delete $attr_def->{'build'} }
    elsif (exists $attr_def->{'lazy_build'}){$self->{'build'} = delete $attr_def->{'lazy_build'}; $self->{'lazy'} = 1; }

    return "$error_start lacks property 'get' or 'auto_get'" unless exists $attr_def->{'get'} or exists $attr_def->{'auto_get'};
    push @{$self->{'methods'}}, @{delete $attr_def->{'get'}} if ref $attr_def->{'get'} eq 'ARRAY';
    push @{$self->{'methods'}},   delete $attr_def->{'get'}  if not ref $attr_def->{'get'} and exists $attr_def->{'get'};
    push @{$self->{'methods'}}, @{delete $attr_def->{'set'}} if ref $attr_def->{'set'} eq 'ARRAY';
    push @{$self->{'methods'}},   delete $attr_def->{'set'}  if not ref $attr_def->{'set'} and exists $attr_def->{'set'};

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

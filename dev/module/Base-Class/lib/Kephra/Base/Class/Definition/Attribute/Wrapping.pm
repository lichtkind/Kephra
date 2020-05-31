use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Attribute::Wrapping;
our $VERSION = 0.1;

################################################################################
sub new {        # ~pkg %attr_def            --> ._ | ~errormsg
    my ($pkg, $attr_def) = (@_);
    return "need a property hash to create a wrapping attribute definition" unless ref $attr_def eq 'HASH';
    my $error_start = ("wrapping attribute $attr_def->{name}");
    my $self = {methods => [], auto => {}};
    for (qw/name help class wrap/) {
        return "$error_start lacks property '$_'" unless exists $attr_def->{$_};
        $self->{$_} = delete $attr_def->{$_};
    }
    return "method definition (property 'wrap') of $error_start has to be a method name or an array (reference) with method names"  
        if ref $self->{'wrap'} and ref $self->{'wrap'} ne 'ARRAY';

    $self->{'require'} = delete $attr_def->{'require'} if exists $attr_def->{'require'};

    $self->{'lazy'} = 0;
    if   (exists $attr_def->{'build'})     {$self->{'build'} = delete $attr_def->{'build'} }
    elsif (exists $attr_def->{'lazy_build'}){$self->{'build'} = delete $attr_def->{'lazy_build'}; $self->{'lazy'} = 1; }

    for (keys %$attr_def){ return "$error_start has the illegal, malformed or effectless property '$_'"  }
    bless $self;
}
################################################################################
sub state   { $_[0] }
sub restate { bless shift }
################################################################################
sub get_kind  {'wrapping'}
sub get_help  {$_[0]->{'help'}}
sub get_type  { undef }
sub get_init  { undef }
sub get_build {$_[0]->{'build'}}
sub is_lazy   {$_[0]->{'lazy'}}
sub accessor_names  {@{ $_[0]->{'methods'}} }
sub auto_accessors  { undef }
sub get_dependency  { undef }
sub get_requirement { $_[0]->{'require'} // $_[0]->{'class'} }

1;

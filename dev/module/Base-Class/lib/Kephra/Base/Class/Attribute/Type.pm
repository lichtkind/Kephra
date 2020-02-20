use v5.16;
use warnings;

# object that holds all types of a class

package Kephra::Base::Class::Attribute::Type;  # types with acess to attributes
our $VERSION = 0.04;
use Kephra::Base::Data::Type::Relative;

sub new {  my ($pkg) = @_;   bless { } }

sub add            { # ~name %def -->  bool         %def : parent @check default? help?
    my ($self, $type, $def) = @_;
    return 0 if $self->is_known($type);           # need a new tye id
    return 0 unless ref $def eq 'HASH' and exists $def->{'parent'};  # complete def
    return 0 unless ref $def->{'check'} eq 'ARRAY' and not @{$def->{'check'}} % 2; # checks are well formed
    for (my $i = 0; $i < @{$def->{'check'}}; $i+=2){
        return 0 if ref $def->{'check'}[$i];
        return 0 unless ref $def->{'check'}[$i+1] eq 'CODE';
    }
    if (Kephra::Base::Data::Type::is_known($def->{'parent'})){ # when child of other class type
        $def->{'default'} = Kephra::Base::Data::Type::default_value($def->{'parent'}) unless exists $def->{'default'};
        unshift @{$def->{'check'}}, @{Kephra::Base::Data::Type::get_checks($def->{'parent'})};
    } elsif (exists $self->{'type'}{$def->{'parent'}}){
        $def->{'default'} = $self->{'type'}{$def->{'parent'}}{'default'} unless exists $def->{'default'};
        unshift @{$def->{'check'}}, @{ $self->{'type'}{$def->{'parent'} }{'check'}};
    } else { return 0 }
    $self->{'type'}{$type} = {check => $def->{'check'}, default => $def->{'default'}};
    1;
}
sub delete         { # name                       -->  bool
    my ($self, $type) = @_;
    return 0 unless exists $self->{'type'}{$type};
    delete $self->{'type'}{$type};
}

################################################################################

sub list_names    {  #                            --> [name]
    sort(keys %{$_[0]->{'type'}}, Kephra::Base::Data::Type::list_names())
}
sub is_known      { # name                        -->  bool
    my ($self, $type) = @_;
    (exists $self->{'type'}{$type} or Kephra::Base::Data::Type::is_known($type)) ? 1 : 0;
}
sub get_default_value  { # name                       --> val|undef
    my ($self, $type) = @_;
    (exists $self->{'type'}{$type}) ? $self->{'type'}{$type}{'default'}
                                    : Kephra::Base::Data::Type::get_default_value($type);
}

sub get_callback { # type                       --> &callback
    my ($self, $type) = @_;
    if (Kephra::Base::Data::Type::is_known($type)) {return Kephra::Base::Data::Type::get_callback($type)}
    elsif (exists $self->{'type'}{$type})          {return $self->{'type'}{$type}{'callback'} if exists $self->{'type'}{$type}{'callback'}}
    else                                           {return "type $type unknown  to class ".$self->{'class'} }
    my $c = $self->{'type'}{$type}{'check'};
    my $l = @$c;
    no warnings "all";
    $self->{'type'}{$type}{'callback'} = sub {
        my ($val, $access_self) = @_;
        for (my $i = 0; $i < $l; $i+=2){return "value: $val needed to be of type $type, but failed test: $c->[$i]" unless $c->[$i+1]->($val, $access_self)};'';
    }
}

################################################################################

sub check          { # name val                   --> help|''
    my ($self, $type, $value, $attribute) = @_;
    my $callback = $self->get_callback($type);
    return $callback unless ref $callback;
    if (ref $self->{'type'}{$type}){
        return "need an attribute as third parameter for type check" unless ref $attribute;
        $callback->($value, $attribute);
    } else {$callback->($value) }
}

1;
__END__
my %set = (list_index  => {check => ['index of list',          sub{$_[0] < @{$_[1]->get()} }], parent => 'int+'},);
sub check_defaults {
    my ($self, $access_scope_self) = @_;
    for my $type (keys %{$self->{'type'}}){
         my $msg = $self->check($type, $self->{'type'}{$type}{default}, $access_scope_self);
         return $msg if $msg;
    }
    '';
}

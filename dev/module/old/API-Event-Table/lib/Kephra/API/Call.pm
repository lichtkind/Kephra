use v5.14;
use warnings;

package Kephra::API::Call;
use parent qw(Kephra::API::Object);
use Kephra::API qw/:log/;

sub BUILD        {  # src. act. --> obj                                        =self:/code ref active/
    my ($self, $source, $active) = @_;
    return error('need at least one parameter with perl code as content') unless defined $source;
    return error('need maximum of two parameter: source (perl code) and active status (bool)') if @_ > 3;

    eval '$self->{ref}'." = sub {$source}";

    if ($@) {
        return error("call source '$source' could not be evaluated: $@");
    } else {
        $self->{source} = $source;
        $active = 1 unless defined $active;
        $self->set_active($active);
        return $self;
    }
}

sub get_source   {  #           --> source(str)        getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{source};
}

sub is_active    {  #           --> bool               getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{active};
}

sub set_active   {  # bool      --> bool               setter
    my ($self, $active) = @_;
    return error('need only a boolean value to set active status') unless defined $active or @_ > 2;
    $self->{active} = $active ? 1 : 0;
}

sub run          {  #           --> retval
    return error('need to be called as method with parameter') if @_ < 1;
    my ($self, @params) = @_;
    # note run
    return undef unless $self->{active};
    $self->{ref}->(@params);
}

################################################################################

sub status       {  #           --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my $r = $self->is_active() ? 'active' : 'inactive';
    $r .= ' : '.$self->get_source();;
}

1;

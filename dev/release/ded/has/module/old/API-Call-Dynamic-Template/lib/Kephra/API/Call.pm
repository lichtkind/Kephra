use v5.14;
use warnings;

package Kephra::API::Call;
use parent qw(Kephra::API::Object);
use Kephra::API qw/:log/;

################################################################################

sub BUILD        { # name src. act? --> obj                                    =self:/name source coderef active template/
    my ($self, $name, $source, $active) = @_;
    return error('need two to three parameter: name, source code and active status (bool)') if @_ < 3 or 4 < @_;

    eval '$self->{coderef}'." = sub {$source}";

    if ($@) {
        return error("call source code '$source' could not be evaluated: $@");
    } else {
        $self->{name}   = $name;
        $self->{source} = $source;
        $self->set_active(defined $active ? $active : 1);
        return $self;
    }
}

################################################################################

sub run          { # @param    --> retval
    return error('need to be called as method with parameter') if @_ < 1;
    my ($self, @params) = @_;
    return unless $self->{active};
    # note("run call $self".($self->{name} ? " named $self->{name}" : ''));
    $self->{coderef}->(@params);
}

################################################################################

sub source       { #           --> str                getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{source};
}

sub name         { #           --> str                getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{name};
}

sub is_active    { #           --> bool               getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{active};
}

sub set_active   { # bool      --> bool               setter
    my ($self, $active) = @_;
    return error('need only a boolean value to set active status') if @_ != 2;
    $self->{active} = $active ? 1 : 0;
}

################################################################################

sub status       {  #           --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my $r = $self->name();
    $r .= ' : '.$self->source();
    $r .= ' : '.($self->is_active() ? 'active' : 'inactive');
}

1;

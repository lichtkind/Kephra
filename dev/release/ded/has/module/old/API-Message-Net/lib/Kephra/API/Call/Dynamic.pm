use v5.14;
use warnings;

package Kephra::API::Call::Dynamic;
use parent      qw(Kephra::API::Call);
use Kephra::API qw/:log/;

################################################################################

sub BUILD        {  # name ref|type src. act? --> obj                          =self:/source ref active/
    my ($self, $name, $ref_or_type, $source, $active) = @_;
    return error('need three to four parameter: name, ref or type, source code and active status (bool)') if @_ < 4 or 5 < @_;
    return error('source code does not use "$ref->", looks like normal call would be enough') unless index($source, '$ref->') > -1;

    eval '$self->{coderef} = sub {my $ref = shift;'." $source}";

    if ($@) {
        return error("call source code '$source' could not be evaluated: $@");
    } else {
        $self->{name} = $name ;
        $self->{source} = $source;
        $self->{ref} = $ref_or_type if ref $ref_or_type;
        $self->{reftype} = ref $ref_or_type ? ref $ref_or_type : $ref_or_type;
        $self->set_active((defined $active and not $active) ? 0 : 1);
        return $self;
    }
}

sub run          {  # @param        --> retval
    return error('need to be called as method with parameter') if @_ < 1;
    return warning('have no reference for dynamic call') unless $_[0]->{ref};
    my ($self, @params) = @_;
    return unless $self->{active};
    # note("run dynamic call $self".($self->{name} ? " named $self->{name}" : ''));
    $self->{coderef}->( $self->{ref}, @params );
}

################################################################################

sub ref_type     { #                --> str               getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{reftype};
}

sub get_reference { #               --> ref               getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{ref};
}

sub set_reference { # ref           --> 1                 setter
    my ($self, $ref) = @_;
    return error("need only a reference of type $_[0]->{reftype} as parameter") if @_ != 2;
    return error("reference is not of type $_[0]->{reftype}") if ref $ref ne $self->{reftype};
    $self->{ref} = $ref;
}

################################################################################

sub status       {  #               --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my ($self) = @_;
    my $r = $self->is_active() ? 'active' : 'inactive';
    $r .= ' : '.$self->source();
    $r;
}

1;

use v5.14;
use warnings;

package Kephra::API::Call::Dynamic::Template;
use parent      qw/Kephra::API::Call::Template/;
use Kephra::API qw/:log :test/;
use Kephra::API::Call::Dynamic;

################################################################################

sub BUILD         { # name ref|type srcl srcr? act?    --> obj                 =self:/source_left source_right/
    my ($self, $name, $ref_or_type, $source_left, $source_right, $active) = @_;
    return error('need three to five parameter: name, ref or type, code template (left and right part) and active status (bool)') if @_ < 4 or 6 < @_;
    $self->{name} = $name ;
    $self->{ref} = $ref_or_type if ref $ref_or_type;
    $self->{reftype} = ref $ref_or_type ? ref $ref_or_type : $ref_or_type;
    $self->{source_left} = $source_left;
    $self->{source_right} = $source_right // ''; #/
    $self->set_active((defined $active and not $active) ? 0 : 1);
    $self;
}

sub new_dynatemplate { # name ref|type sll slr? srl? srr? --> obj              =sll:Source Left of (former) Left part
    my ($self, $name, $ref_or_type, $left_of_left, $right_of_left, $left_of_right, $right_of_right) = @_;
    return error('need three to six parameter: name, ref or type and template parts to be attached left and right to previous two (L,R) - 1L2 3R4')
        if @_ < 4 or 7 < @_;
    return error('referece has to have type '.$self->{reftype}) unless not ref $ref_or_type 
                                                                   or (ref $ref_or_type eq $self->{reftype})
                                                                   or (blessed($ref_or_type) and $ref_or_type->can($self->{reftype}));
    $ref_or_type = $ref_or_type ? $ref_or_type : $self->{ref} ? $self->{ref} : $self->{reftype};
    my $left = $left_of_left . $self->source_part_left();
    $left .= $right_of_left if defined $right_of_left;
    my $right = $self->source_part_right();
    $right = $left_of_right . $right if defined $left_of_right;
    $right .= $right_of_right if defined $right_of_right;
    __PACKAGE__->new( $name, $ref_or_type, $left, $right, $self->is_active() );
}

sub new_dynacall  { # name ref|type srcl srcr? act?    --> dynacall
    my ($self, $name, $ref_or_type, $call_src_left, $call_src_right, $active) = @_;
    return error('need three to five parameter: name, ref or type, code template (left and right part) and active status (bool)') if @_ < 4 or 6 < @_;
    return error('referece has to have type '.$self->{reftype}) unless not ref $ref_or_type 
                                                                   or (ref $ref_or_type eq $self->{reftype})
                                                                   or (blessed($ref_or_type) and $ref_or_type->can($self->{reftype}));
    $ref_or_type = $ref_or_type ? $ref_or_type : $self->{ref} ? $self->{ref} : $self->{reftype};
    my $source = $self->{source_left} . $call_src_left;
    $source .= $self->{source_right};
    $source .= $call_src_right       if defined $call_src_right;
    $active = $self->is_active() unless defined $active;
    Kephra::API::Call::Dynamic->new($name, $ref_or_type, $source, $active);
}

################################################################################

sub ref_type      { #                    --> str               getter
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

sub status        {  #                    --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my $r = "source: $_[0]->{source_left} ";
    $r .= "... $_[0]->{source_right}" if defined $_[0]->{source_right};
    $r;
}


1;

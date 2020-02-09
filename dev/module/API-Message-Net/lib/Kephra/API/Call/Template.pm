use v5.14;
use warnings;

package Kephra::API::Call::Template;
use parent qw(Kephra::API::Object);
use Kephra::API qw/:log/;
use Kephra::API::Call;

################################################################################

sub BUILD         {  # name srcl srcr? act?    --> obj                      =self:/name active source_left source_right/
    my ($self, $name, $source_left, $source_right, $active) = @_;
    return error('need two to four parameter: name, code template (left and right part) and call state (bool)') if @_ < 3 or 5 < @_;
    $self->{name} = $name;
    $self->{source_left} = $source_left;
    $self->{source_right} = defined $source_right ? $source_right : '';
    $self->set_active(defined $active ? $active : 1);
    $self;
}

sub new_template  {  # name sll slr? srl? srr? --> obj                      =sll:Source Left of (former) Left part 
    my ($self, $name, $left_of_left, $right_of_left, $left_of_right, $right_of_right) = @_;
    return error('need two to five parameter: name and template parts to be attached left and right to previous two (L,R) - 1L2 3R4') if @_ < 3 or 6 < @_;
    my $left = $left_of_left . $self->source_part_left();
    $left .= $right_of_left if defined $right_of_left;
    my $right = $self->source_part_right();
    $right = $left_of_right . $right if defined $left_of_right;
    $right .= $right_of_right if defined $right_of_right;
    __PACKAGE__->new( $name, $left, $right, $self->is_active() );
}

sub new_call      {  # name srcl srcr? act.?   --> call
    my ($self, $name, $call_src_left, $call_src_right, $active) = @_;
    return error('need two to four parameter: name, source left, source right and active status (bool)') if @_ < 3 or 5 < @_;
    my $source = $self->{source_left} . $call_src_left;
    $source .= $self->{source_right};
    $source .= $call_src_right       if defined $call_src_right;
    $active = $self->is_active() unless defined $active;
    Kephra::API::Call->new($name, $source, $active);
}

################################################################################

sub name             { #              --> str                getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{name};
}

sub source_part_left { #              --> str                getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{source_left}
}

sub source_part_right{ #              --> str                getter
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{source_right}
}

sub is_active        { #              --> bool               getter            =active:create active calls
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{active};
}

sub set_active       { # bool         --> bool               setter
    my ($self, $active) = @_;
    return error('need only a boolean value to set active status') if @_ != 2;
    $self->{active} = $active ? 1 : 0;
}

################################################################################

sub status           { #              --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my $r = "source: $_[0]->{source_left} ";
    $r .= "... $_[0]->{source_right}" if defined $_[0]->{source_right};
    $r;
}

1;

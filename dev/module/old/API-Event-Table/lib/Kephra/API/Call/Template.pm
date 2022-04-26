use v5.14;
use warnings;

package Kephra::API::Call::Template;
use parent qw(Kephra::API::Object);
use Kephra::API qw/:log/;
use Kephra::API::Call;

sub BUILD         {  # srcl srcr?       --> obj                                =self:/source_left source_right/
    my ($self, $source_left, $source_right) = @_;
    return error('need one or two parameter with perl code as content') if @_ > 3 or not defined $source_left;
    $self->{source_left} = $source_left;
    $self->{source_right} = $source_right // '';
    $self;
}

sub source_part_left {  #              --> srcl
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{source_left}
}

sub source_part_right {  #              --> srcl
    return error('need to be called as method with no parameter') if @_ != 1;
    $_[0]->{source_right}
}
################################################################################

sub new_call      {  # srcl srcr? act.? --> call
    my ($self, $call_src_left, $call_src_right, $active) = @_;
    return error('need at least one parameter with perl code as content') unless defined $call_src_left;
    return error('need maximum of three parameter: source left, source right and active status (bool)') if @_ > 4;
    my $source = $self->{source_left}.$call_src_left;
    $source .= $self->{source_right} if defined $self->{source_right};
    $source .= $call_src_right       if defined $call_src_right;
    Kephra::API::Call->new($source, $active);
}

################################################################################

sub status        {  #                  --> ref
    return error('need to be called as method with no parameter') if @_ != 1;
    my $r = "source: $_[0]->{source_left} ";
    $r .= "... $_[0]->{source_right}" if defined $_[0]->{source_right};
    $r;
}


1;

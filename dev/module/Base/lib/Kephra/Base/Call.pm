use v5.20;
use warnings;

# serializable closure

package Kephra::Base::Call;
our $VERSION = 0.5;
use Exporter 'import';
our @EXPORT_OK = (qw/new_call/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
use Kephra::Base::Data qw/clone_data/;
################################################################################
sub new_call   {new(__PACKAGE__, @_)}
sub new {
    my ($pkg, $source, $state, $type) = @_;
    if (ref $source eq 'HASH'){
        $type     = $source->{'type'} if exists $source->{'type'};
        $state    = $source->{'state'} if exists $source->{'state'};
        $source   = exists $source->{'source'} ? $source->{'source'} : undef;
    }
    return 'need at least one argument: the perl source code to run as this call' unless defined $source;
    $type = Kephra::Base::Data::Type::get($type) unless not defined $type or ref $type;
    return "third or named argument 'type' has to be a Kephra::Base::Data::Type::Simple object or the name of a standard type"
        if defined $type and ref $type ne 'Kephra::Base::Data::Type::Simple';
    return 'start value $state does not match type: '.$type->get_name if defined $state and defined $type and $type->check( $state );
    $state = clone_data($state);
    my $code = eval "sub {$source}";
    return "can not create call object, because source code - '$source' - evaluates with error: $@" if $@;
    bless { source => $source, code => $code, state => \$state, type => $type };
}
sub clone { 
    my ($origin, $state) = @_;
    my $source = $origin->get_source();
    $state //= ${$origin->{'state'}};
    $state = clone_data($state);    bless { source => $source, code => eval "sub {$source}", state => \$state, type => $origin->get_type() };
}
sub restate {
    my ($pkg, $obj_state) = @_;
    return 'need a hash ref with at least state property "source"' unless ref $obj_state eq 'HASH' and exists $obj_state->{'source'};
    my $state = clone_data( $obj_state->{'state'} );
    my $code = eval "sub {$obj_state->{source}}";
    return "can not create call object, because sources - $obj_state->{source} - evaluates with error: $@" if $@;
    my $type = (ref $obj_state->{'type'} eq 'HASH') ? Kephra::Base::Data::Type::Simple->new($obj_state->{'type'}) : undef; 
    bless {source => $obj_state->{'source'}, code => $code, state => \$state, type => $type};
}
sub state {
    {source => $_[0]->{'source'}, state => ${$_[0]->{'state'}}, type => (defined $_[0]->{'type'} and $_[0]->{'type'}) ? $_[0]->{'type'}->state : undef };
}
################################################################################
sub get_source { $_[0]->{'source'} }
sub get_type   { $_[0]->{'type'} }
sub get_state  { ${$_[0]->{'state'}} }
sub set_state  { ${$_[0]->{'state'}} = $_[1] unless $_[0]->{'type'} and $_[0]->{'type'}->check($_[1]) }
################################################################################
sub run { my ($self) = shift; $self->{'code'}->(@_) }
################################################################################

1;

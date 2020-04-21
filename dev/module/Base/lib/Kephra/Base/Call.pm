use v5.20;
use warnings;

# serializable closure

package Kephra::Base::Call;
our $VERSION = 0.4;
use Exporter 'import';
our @EXPORT_OK = (qw/new_call/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
use Kephra::Base::Data qw/clone_data/;
################################################################################
sub new_call   {new(__PACKAGE__, @_)}
sub new {
    my ($pkg, $source, $state, $set_type, $get_type) = @_;
    if (ref $source eq 'HASH'){
        $get_type = $source->{'get_type'} if exists $source->{'get_type'};
        $set_type = $source->{'set_type'} if exists $source->{'set_type'};
        $state    = $source->{'state'} if exists $source->{'state'};
        $source   = exists $source->{'source'} ? $source->{'source'} : undef;
    }
    return 'need at least one argument: the perl source code to run as this call' unless defined $source;
    return "set type: $set_type does not exist" if defined $set_type and not Kephra::Base::Data::Type::is_known( $set_type );
    return "get type: $get_type does not exist" if defined $get_type and not Kephra::Base::Data::Type::is_known( $get_type );
    return "start value $state does not match set type: $set_type" if defined $state and defined $set_type and Kephra::Base::Data::Type::check( $set_type, $state );
    $state = clone_data($state);
    my $code = eval "sub {$source}";
    return "can not create call object, because sources - $source - evaluates with error: $@" if $@;
    bless { source => $source, code => $code, state => \$state, get_type => $get_type, set_type => $set_type };
}
sub clone { 
    my ($origin, $state) = @_;
    my $source = $origin->get_source();
    $state //= ${$origin->{'state'}};
    $state = clone_data($state);    bless { source => $source, code => eval "sub {$source}", state => \$state, set_type => $origin->get_settype(), get_type => $origin->get_gettype() };
}
sub restate {
    my ($pkg, $property) = @_;
    return 'need a hash ref with at least state property "source"' unless ref $property eq 'HASH' and exists $property->{'source'};
    my $state = exists $property->{'state'} ? clone_data( $property->{'state'} ) : '';
    my $self  = bless {source => $property->{'source'}, state => \$state};
    $self->{'get_type'} = $property->{'get_type'} if exists $property->{'get_type'};
    $self->{'set_type'} = $property->{'set_type'} if exists $property->{'set_type'};
    $self->{'code'} = eval "sub {$property->{source}}";
    return "can not create call object, because sources - $state->{source} - evaluates with error: $@" if $@;
    $self;
}
sub state {
    {source => $_[0]->{'source'}, state => ${$_[0]->{'state'}}, get_type => $_[0]->{'get_type'}, set_type => $_[0]->{'set_type'}};
}
################################################################################
sub get_source { $_[0]->{'source'} }
sub get_gettype{ $_[0]->{'get_type'} }
sub get_settype{ $_[0]->{'set_type'} }
sub get_state  { ${$_[0]->{'state'}} unless $_[0]->{'get_type'} and Kephra::Base::Data::Type::check( $_[0]->{'get_type'}, ${$_[0]->{'state'}}) }
sub set_state  { ${$_[0]->{'state'}} = $_[1] unless $_[0]->{'set_type'} and Kephra::Base::Data::Type::check( $_[0]->{'set_type'}, $_[1]); ${$_[0]->{'state'}} }
################################################################################
sub run {
    my ($self) = shift;
    $self->{'code'}->(@_);
}
################################################################################

1;

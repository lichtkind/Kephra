use v5.20;
use warnings;

package Kephra::Base::Call;
our $VERSION = 0.01;
use Exporter 'import';
our @EXPORT_OK = (qw/new_call/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
use Kephra::Base::Data;
################################################################################
sub new_call   {new(__PACKAGE__, @_)}
sub new {
    my ($pkg, $source, $state, $set_type, $get_type) = @_;
    return 'need at least one argument: the perl source code to run as this call' unless defined $source;
    return "set type: $set_type does not exist" if defined $set_type and not Kephra::Base::Data::Type::is_known( $set_type );
    return "set type: $get_type does not exist" if defined $get_type and not Kephra::Base::Data::Type::is_known( $get_type );
    return "start value $state does not match set type: $set_type" if defined $state and defined $set_type and Kephra::Base::Data::Type::check( $set_type, $state );
    my $code = eval "sub {$source}";
    return "can not create call object, because sources - $source - evaluates with error: $@" if $@;
    bless { source => $source, code => $code, state => \$state, get_type => $get_type, set_type => $set_type };
}
sub clone { 
    my ($origin, $state) = @_;
    $state //= ${$origin->{'state'}};
    my $source = $origin->get_source();
    bless { source => $source, code => eval "sub {$source}", state => \$state, set_type => $origin->get_settype(), get_type => $origin->get_gettype() };
}
################################################################################
sub get_source { $_[0]->{'source'} }
sub get_gettype{ $_[0]->{'get_type'} }
sub get_settype{ $_[0]->{'set_type'} }
sub get_state  { ${$_[0]->{'state'}} unless $_[0]->{'get_type'} and Kephra::Base::Data::Type::check( $_[0]->{'get_type'}, ${$_[0]->{'state'}}) }
sub set_state  { ${$_[0]->{'state'}} = $_[1] unless $_[0]->{'get_type'} and Kephra::Base::Data::Type::check( $_[0]->{'get_type'}, ${$_[0]->{'state'}}) }
################################################################################
sub run {
    my ($self) = shift;
    $self->{'code'}->(@_);
}
################################################################################

1;

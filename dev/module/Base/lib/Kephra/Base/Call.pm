use v5.20;
use warnings;

package Kephra::Base::Call;
our $VERSION = 0.01;
use Exporter 'import';
our @EXPORT_OK = (qw/new_call/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
################################################################################
sub new_call   {new(__PACKAGE__, @_)}
sub new {
    my ($pkg, $source, $state, $type) = @_;
    if (ref $pkg eq __PACKAGE__){
        $state = $source;
        $source = $pkg->get_source();
    }
    my $code = eval "sub {$source}";
    return "can not create call object, because sources - $source eval with error: $@" if $@;
    bless { source => $source, code => $code, state => \$state };
}
sub clone {$_[0]->new( $_[0]->get_state() )}
################################################################################
sub get_source { $_[0]->{'source'} }
sub get_state  { ${$_[0]->{'state'}} }
sub set_state  { ${$_[0]->{'state'}} = $_[1]}
################################################################################
sub run {
    my ($self) = shift;
    $self->{'code'}->(@_);
}
################################################################################

1;

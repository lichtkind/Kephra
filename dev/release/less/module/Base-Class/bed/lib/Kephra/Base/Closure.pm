use v5.20;
use warnings;

# serializable closure

package Kephra::Base::Closure;
our $VERSION = 1.2;
use Exporter 'import';
our @EXPORT_OK = (qw/new_closure/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
use Kephra::Base::Data qw/clone_data check_type is_type_known/;
my $tclass = 'Kephra::Base::Data::Type::Basic';
################################################################################
sub new_closure   {new(__PACKAGE__, @_)}
sub new {
    my ($pkg, $code, $state, $type) = @_;
    if (ref $code eq 'HASH'){
        $type     = $code->{'type'} if exists $code->{'type'};
        $state    = $code->{'state'} if exists $code->{'state'};
        $code   = exists $code->{'code'} ? $code->{'code'} : undef;
    }
    return 'need at least one argument: the perl source code as string to run this closure' unless defined $code;
    my $std_type;
    if (defined $type){
        if (ref $type){
            return "third or named argument 'type' has to be a $tclass object or the name of a initial standard type" if ref $type ne $tclass;
            return 'start value $state does not match type: '.$type->get_name if defined $state and $type->check( $state );
        } else {
            return "third or named argument 'type' has to be a $tclass object or the name of a initial basic standard type" unless is_type_known($type);
            return 'start value $state does not match type: '.$type if defined $state and check_type($type, $state);
            $std_type = $type; 
            $type = undef;
        }
    }
    $state //= $type->get_default_value if defined $type;
    $state = clone_data($state);
    my $coderef = eval "sub {$code}";
    return "can not create call object, because source code - '$code' - evaluates with error: $@" if $@;
    bless { code => $code, coderef => $coderef, state => \$state, type => $type, std_type => $std_type};
}
sub clone { 
    my ($origin, $state) = @_;
    my $code = $origin->get_code();
    $state //= ${$origin->{'state'}};
    $state = clone_data($state);    bless { code => $code, coderef => eval "sub {$code}", state => \$state, type => $origin->{'type'}, std_type => $origin->{'std_type'} };
}
sub restate {
    my ($pkg, $obj_state) = @_;
    return 'need a hash ref with at least state property "source"' unless ref $obj_state eq 'HASH' and exists $obj_state->{'code'};
    my $state = clone_data( $obj_state->{'state'} );
    my $coderef = eval "sub {$obj_state->{code}}";
    return "can not create call object, because source code - $obj_state->{code} - evaluates with error: $@" if $@;
    bless {code => $obj_state->{'code'}, coderef => $coderef, state => \$state, std_type => $obj_state->{'std_type'},
           type => (defined $obj_state->{'type'}) ? Kephra::Base::Data::Type::Basic->restate($obj_state->{'type'}) : undef,};
}
sub state {
    {code => $_[0]->{'code'}, state => ${$_[0]->{'state'}}, std_type => $_[0]->{'std_type'}, type => (defined $_[0]->{'type'}) ? $_[0]->{'type'}->state : undef };
}
################################################################################
sub get_code   { $_[0]->{'code'} }
sub get_type   { (defined $_[0]->{'std_type'}) ? Kephra::Base::Data::Type::Standard::store->get_type($_[0]->{'std_type'}) : $_[0]->{'type'} }
sub get_state  { ${$_[0]->{'state'}} }
sub set_state  {
    my $error = (defined $_[0]->{'type'})     ? $_[0]->{'type'}->check($_[1]) :
                (defined $_[0]->{'std_type'}) ? check_type($_[0]->{'std_type'}, $_[1]) : '';
    $error or (${$_[0]->{'state'}} = $_[1]);
}
################################################################################
sub run { my ($self) = shift; $self->{'coderef'}->(@_) }
################################################################################

9;

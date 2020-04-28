use v5.20;
use warnings;

# data type depending second value (parameter) // example - valid index (type) of an actual array (parameter)
# { name => 'index', help => 'valid index of array', parent => 'int_pos', code =>'return "value $value is out of range" if $value >= @$param', 
#   parameter =>{name => 'array reference', type => 'ARRAY', default => []}, default => 0    }   # type is required
# plans: inheritance?

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 0.5;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Data::Type::Simple;

################################################################################
sub new {   # ~name  ~help  %parameter  ~code  .parent - $default --> .ptype | ~errormsg 
    my ($pkg, $name, $help, $parameter, $code, $parent, $default) = @_;
    if (ref $name eq 'HASH'){
        $parameter = $name->{'parameter'} if exists $name->{'parameter'};
        $default  = $name->{'default'}  if exists $name->{'default'};
        $parent  = $name->{'parent'}  if exists $name->{'parent'};
        $code   = $name->{'code'}   if exists $name->{'code'};
        $help  = $name->{'help'}  if exists $name->{'help'};
        $name = exists $name->{'name'} ? $name->{'name'} : undef;
    }
    return "need the arguments 'name' (str), 'help' (str), 'parameter' (hashref), 'code' (str) ".
           "and 'parent' (Kephra::Base::Data::Type::Simple) to create parametric type object" 
        unless defined $name and defined $help and defined $parameter and defined $code and defined $parent;
    return "parameter definition has to be an hashref and contain the key 'type' (Kephra::Base::Data::Type::Simple) to create parametric type $name" 
        if ref $parameter ne 'HASH' or ref $parameter->{'type'} ne 'Kephra::Base::Data::Type::Simple';
    return "default value '$parameter->{default}' of type $name 's parameter does not match his type $parameter->{type}{name}" 
        if exists $parameter->{'default'} and $parameter->{'type'}->check($parameter->{'default'});
    return "parent has to be instance of Kephra::Base::Data::Type::Simple to create parametric type $name" 
        if ref $parent ne 'Kephra::Base::Data::Type::Simple';
    $default //= $parent->get_default_value;
    if (exists $parameter->{'default'} or exists $parameter->{'name'}){
        $parameter = Kephra::Base::Data::Type::Simple->new( {
                name => $parameter->{'name'} // $parameter->{'type'}->get_name,
                default => $parameter->{'default'} // $parameter->{'type'}->get_default_value,
                parent => $parameter->{'type'} } );
    } else {
        $parameter = $parameter->{'type'};
    }
    my $source = _compile_( $name, $parent->get_checks, $code, $parameter );
    my $coderef = eval $source;
    return "parametric type $name checker source code '$source' could not eval because: $@ !" if $@;
    my $error = $coderef->( $default, $parameter->get_default_value);
    return "type $name default value '$default' with parameter " . $parameter->get_name.' default value ' . $parameter->get_default_value.
           " does not pass check '$source' because: $error!" if $error;
    bless { name => $name, help => $help, code => $code, checks => $parent->get_checks, default => $default,
            coderef => $coderef, trustcoderef => eval _compile_with_safe_param_( $name, $parent->get_checks, $code), parameter => $parameter};
}
sub restate {                                     # %state                -->  .type | ~errormsg
    my ($pkg, $state) = @_;
    $state->{'parameter'} = Kephra::Base::Data::Type::Simple->restate( $state->{'parameter'} );
    $state->{'coderef'} = eval _compile_( $state->{'name'}, $state->{'checks'}, $state->{'code'}, $state->{'parameter'});
    $state->{'trustcoderef'} = eval _compile_with_safe_param_( $state->{'name'}, $state->{'checks'}, $state->{'code'});
    bless $state;
}
################################################################################
sub _compile_ {
    my ($name, $check, $code, $parameter) = @_;
    'sub { my ($param, $value) = @_; no warnings "all";'
    . Kephra::Base::Data::Type::Simple::_asm_("$name parameter ".$parameter->get_name, $parameter->get_checks)
    . '($value, $param)=($param, $value);' . Kephra::Base::Data::Type::Simple::_asm_($name, $check) . $code . ";return ''}"
}
sub _compile_with_safe_param_ {
    my ($name, $check, $code) = @_;
    'sub { my ($value, $param) = @_; no warnings "all";'
    . Kephra::Base::Data::Type::Simple::_asm_($name, $check) . $code . ";return ''}"
}
################################################################################
sub state {                                       # .type                 -->  %state
    { name => $_[0]->{'name'}, help => $_[0]->{'help'}, code => $_[0]->{'code'}, checks => [@{$_[0]->{'checks'}}], 
     default => $_[0]->{'default'}, parameter => $_[0]->{'parameter'}->state() }
}
sub get_name          { $_[0]->{'name'} }            # .type                 -->  ~name
sub get_help          { $_[0]->{'help'} }            # .type                 -->  ~help
sub get_default_value { $_[0]->{'default'} }         # .type                 -->  $default
sub get_checker       { $_[0]->{'coderef'} }         # .type                 -->  &check
sub get_trusting_checker { $_[0]->{'trustcoderef'} } # .type                 -->  &trusting_check  # when parameter is already type checked
################################################################################
sub check     { $_[0]->{'coderef'}->($_[1], $_[2]) } # .type $val $param     -->  ~errormsg
################################################################################

1;

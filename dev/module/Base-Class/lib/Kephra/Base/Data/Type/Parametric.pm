use v5.20;
use warnings;

# serializable data type object that checks values against named and typed arguments if contract holds

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 0.1;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Data::Type::Simple;

################################################################################
sub new {
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
    $parameter->{'default'} //= $parameter->{'type'}->get_default_value;
    $parameter->{'name'} //= $parameter->{'type'}->get_name;
    my $source = _compile_( $name, $parent->get_checks, $code, $parameter );
    my $coderef = eval $source;
    return "parametric type $name checker source code '$source' could not eval because: $@ !" if $@;
    my $error = $coderef->( $default, $parameter->{'default'});
    return "type $name default value '$default' with parameter $parameter->{name} default $parameter->{default} does not pass check '$source' because: $error!" if $error;
    bless { name => $name, coderef => $coderef, code => $code, checks => $parent->get_checks, default => $default };
}
sub restate {                                     # %state                -->  .type | ~errormsg
    my ($pkg, $state) = @_;
    no warnings "all";
    $state->{'callback'} = eval _compile_( $state->{'check'}, $state->{'name'} );
    bless $state;
}
sub _compile_ {
    my ($name, $check, $code, $parameter) = @_;
    'sub { my ($param, $value) = @_; no warnings "all";'
    . Kephra::Base::Data::Type::Simple::_asm_("$name parameter $parameter->{name}", $parameter->{'type'}->get_checks)
    . '($value, $param)=($param, $value);'
    . Kephra::Base::Data::Type::Simple::_asm_($name, $check) . $code . "return ''}";
}
sub _curry_ {
    my ($name, $check, $code, $parameter, $q) = @_;
    'sub { my ($value) = @_; no warnings "all"; my $param = '
    . ($q ? "'$parameter';" : "$parameter;")
    . Kephra::Base::Data::Type::Simple::_asm_($name, $check) . $code . "return ''}";
}
################################################################################
sub state {                                       # .type                 -->  %state
    { name => $_[0]->{'name'}, check => [@{$_[0]->{'check'}}], default => $_[0]->{'default'} }
}
sub get_name          { $_[0]->{'name'} }         # .type                 -->  ~name
#sub get_checks        { $_[0]->{'check'} }        # .type                 -->  @check
sub get_default_value { $_[0]->{'default'} }      # .type                 -->  $default
################################################################################
sub curry        { $_[0]->{'coderef'}->($_[1]) } # .type $param          -->  .type | ~errormsg
sub check  { $_[0]->{'coderef'}->($_[1], $_[2]) } # .type $val $param     -->  ~errormsg
################################################################################

1;

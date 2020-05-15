use v5.20;
use warnings;

# data type depending second value (parameter) // example - valid index (type) of an actual array (parameter)
# { name => 'index', help => 'valid index of array', parent => 'int_pos', code =>'return "value $value is out of range" if $value >= @$param', default => 0,
#   parameter =>{name => 'ARRAY', help => 'array reference', code => 'ref $value eq "ARRAY"', default => []}    }   # type is required

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 1.3;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Data::Type::Basic;         my $btype = 'Kephra::Base::Data::Type::Basic';

################################################################################
sub _unhash_arg_ {
    ref $_[0] eq 'HASH' ? ($_[0]->{'name'}, $_[0]->{'help'}, $_[0]->{'parameter'}, $_[0]->{'code'}, $_[0]->{'parent'}, $_[0]->{'default'}) : @_;
}
sub new {   # ~name  ~help  %parameter  ~code  .parent - $default            --> .ptype | ~errormsg 
    my $pkg = shift;
    my ($name, $help, $parameter, $code, $parent, $default) = _unhash_arg_(@_);
    return "need the arguments 'name' (str), 'help' (str), 'parameter' (hashref), 'code' (str) and 'parent' ($btype) to create parametric type object" 
        unless defined $name and $name and defined $help and $help and defined $code and $code and defined $parent;
    return "parent has to be instance of $btype or ".__PACKAGE__." to create parametric type $name" if ref $parent ne $btype and ref $parent ne __PACKAGE__;
    if (ref $parent eq __PACKAGE__){
        $parameter //= $parent->get_parameter;
        $code = $parent->{'code'}.';'.$code;
    }
    return "argument 'parameter' of parametric type $name has to be $btype or a hash ref definition " if ref $parameter ne $btype and ref $parameter ne 'HASH';
    $parameter = Kephra::Base::Data::Type::Basic->new( $parameter ) if ref $parameter eq 'HASH';
    return "'parameter' definition of parametric type $name has issue: $parameter " unless ref $parameter;
    $default //= $parent->get_default_value;
    my $checks = $parent->{'checks'};
    my $source = _compile_( $name, $checks, $code, $parameter );
    my $coderef = eval $source;
    return "parametric type '$name' checker source code - '$source' - could not eval because: $@ !" if $@;
    my $error = $coderef->( $default, $parameter->get_default_value);
    return "type '$name' default value '$default' with parameter '" . $parameter->get_name.'\' default value \'' . $parameter->get_default_value.
           "' does not pass check - '$source' - because: $error!" if $error;
    bless { name => $name, help => $help, code => $code, checks => $checks, default => $default,
            coderef => $coderef, trustcoderef => eval _compile_with_safe_param_( $name, $checks, $code), parameter => $parameter};
}
sub restate {                                        # %state                -->  .ptype | ~errormsg
    my ($pkg, $state) = @_;
    $state->{'parameter'} = Kephra::Base::Data::Type::Basic->restate( $state->{'parameter'} );
    $state->{'coderef'} = eval _compile_( $state->{'name'}, $state->{'checks'}, $state->{'code'}, $state->{'parameter'});
    $state->{'trustcoderef'} = eval _compile_with_safe_param_( $state->{'name'}, $state->{'checks'}, $state->{'code'});
    bless $state;
}
################################################################################
sub _compile_ {
    my ($name, $check, $code, $parameter) = @_;
    'sub { my ($param, $value) = @_; no warnings "all";'
    . Kephra::Base::Data::Type::Basic::_asm_("$name parameter ".$parameter->get_name, $parameter->get_check_pairs)
    . '($value, $param)=($param, $value);' . Kephra::Base::Data::Type::Basic::_asm_($name, $check) . $code . ";return ''}"
}
sub _compile_with_safe_param_ {
    my ($name, $check, $code) = @_;
    'sub { my ($value, $param) = @_; no warnings "all";'
    . Kephra::Base::Data::Type::Basic::_asm_($name, $check) . $code . ";return ''}"
}
################################################################################
sub state {                                          # .ptype                -->  %state
    { name => $_[0]->{'name'}, help => $_[0]->{'help'}, code => $_[0]->{'code'}, checks => [@{$_[0]->{'checks'}}], 
     default => $_[0]->{'default'}, parameter => $_[0]->{'parameter'}->state() }
}
sub get_name          { $_[0]->{'name'} }            # .ptype                -->  ~name
sub get_help          { $_[0]->{'help'} }            # .ptype                -->  ~help
sub get_default_value { $_[0]->{'default'} }         # .ptype                -->  $default
sub get_parameter     { $_[0]->{'parameter'} }       # .ptype                -->  .btype
sub get_checker       { $_[0]->{'coderef'} }         # .ptype                -->  &check
sub get_trusting_checker { $_[0]->{'trustcoderef'} } # .ptype                -->  &trusting_check  # when parameter is already type checked
################################################################################
sub check     { $_[0]->{'coderef'}->($_[1], $_[2]) } # .ptype $val $param    -->  ~errormsg
################################################################################

2;

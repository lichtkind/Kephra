use v5.20;
use warnings;
use feature "switch";
no warnings 'experimental::smartmatch';

# data type depending on second value (parameter) 
# example:     valid index (type) of an actual array (parameter)
#              { name => 'index', help => 'valid index of array', parent => 'int_pos', 
#                code =>'return "value $value is out of range" if $value >= @$param', default => 0,
#           parameter =>{name => 'ARRAY', help => 'array reference', code => 'ref $value eq "ARRAY"', default => []}    }   # type is required

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 1.5;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Data::Type::Basic;         my $btype = 'Kephra::Base::Data::Type::Basic';

################################################################################
sub _unhash_arg_ {
    ref $_[0] eq 'HASH' ? ($_[0]->{'name'}, $_[0]->{'help'}, $_[0]->{'parameter'}, $_[0]->{'code'}, $_[0]->{'parent'}, $_[0]->{'default'}) : @_;
}
sub new {   # ~name  ~help  %parameter|.parameter  ~code  .parent - $default    --> .ptype | ~errormsg 
    my $pkg = shift;
    my ($name, $help, $parameter, $code, $parent, $default) = _unhash_arg_(@_);
    my $name_error = Kephra::Base::Data::Type::Basic::_check_name($name);
    return $name_error if $name_error;
    return "need the arguments 'name' (str), 'help' (str), 'parameter' (hashref), 'code' (str) ".
        "and maybe 'parent' ($btype) to create parametric type object" unless defined $code and $code and $help ;
    return "parent has to be instance of $btype or ".__PACKAGE__." to create parametric type $name"
        if defined $parent and $parent and ref $parent ne $btype and ref $parent ne __PACKAGE__;

    my $parents = {};
    my $checks = [];
    if (ref $parent){
        if (ref $parent eq __PACKAGE__){
            $code = $parent->{'code'}.';'.$code;
            $parameter //= $parent->parameter;
            return "parent has to to have the same or derived parameter type" unless $parent->parameter->name eq $parameter->name
                                                                                  or $parent->parameter->name ~~ $parameter->parents;
            %$parents = %{$parent->parents};
            $parents->{ $parent->name } = $parent->parameter->name;
        } else {
            $parents->{$_} = '' for @{$parent->parents}, $parent->name;
        }
        $checks = $parent->{'checks'};
        $default //= $parent->default_value;
    }
    return "parametric type $name need to get or inherit a default value " unless defined $default;    
    return "argument 'parameter' of parametric type $name has to be $btype or a hash ref definition "
        if ref $parameter ne $btype and ref $parameter ne 'HASH';
    $parameter = Kephra::Base::Data::Type::Basic->new( $parameter ) if ref $parameter eq 'HASH';
    return "'parameter' definition of parametric type $name has issue: $parameter " unless ref $parameter;

    my $error_start = "type '$name' with parameter '".$parameter->name."'";
    my $source = _compile_( $name, $checks, $code, $parameter );
    my $coderef = eval $source;
    return "$error_start has bad source code : '$source' - could not eval because: $@ !" if $@;
    my $error = $coderef->( $default, $parameter->default_value);
    return "$error_start default value '". $parameter->default_value."' does not pass check - '$source' - because: $error!" if $error;
    bless { name => $name, help => $help, code => $code, checks => $checks, default => $default, parents => $parents,
            coderef => $coderef, trustcoderef => eval _compile_with_safe_param_( $name, $checks, $code), parameter => $parameter};
}
################################################################################
sub restate {                                        # %state                -->  .ptype | ~errormsg
    my ($pkg, $state) = @_;
    $state->{'parameter'} = Kephra::Base::Data::Type::Basic->restate( $state->{'parameter'} );
    $state->{'coderef'} = eval _compile_( $state->{'name'}, $state->{'checks'}, $state->{'code'}, $state->{'parameter'});
    $state->{'trustcoderef'} = eval _compile_with_safe_param_( $state->{'name'}, $state->{'checks'}, $state->{'code'});
    bless $state;
}
sub state {                                          # _                     -->  %state
    { name => $_[0]->{'name'}, help => $_[0]->{'help'}, code => $_[0]->{'code'}, checks => [@{$_[0]->{'checks'}}],
      parents => {%{$_[0]->{'parents'}}}, default => $_[0]->{'default'}, parameter => $_[0]->{'parameter'}->state() }
}
################################################################################
sub _compile_ {
    my ($name, $check, $code, $parameter) = @_;
    'sub { my ($param, $value) = @_; no warnings "all";'
    . Kephra::Base::Data::Type::Basic::_asm_("$name parameter ".$parameter->name, $parameter->source)
    . '($value, $param)=($param, $value);' . Kephra::Base::Data::Type::Basic::_asm_($name, $check) . $code . ";return ''}"
}
sub _compile_with_safe_param_ {
    my ($name, $check, $code) = @_;
    'sub { my ($value, $param) = @_; no warnings "all";'
    . Kephra::Base::Data::Type::Basic::_asm_($name, $check) . $code . ";return ''}"
}
################################################################################
sub name          { $_[0]->{'name'} }            # _                     -->  ~PTname
sub parents       { $_[0]->{'parents'} }         # _                     -->  %_parent.name -> :parent:parameter:name
sub help          { $_[0]->{'help'} }            # _                     -->  ~help
sub default_value { $_[0]->{'default'} }         # _                     -->  $default
sub parameter     { $_[0]->{'parameter'} }       # _                     -->  .btype
sub checker       { $_[0]->{'coderef'} }         # _                     -->  &check
sub trusting_checker { $_[0]->{'trustcoderef'} } # _                     -->  &trusting_check  # when parameter is already type checked
################################################################################
sub has_parent        {                       # _ ~BTname|[~PTname ~BTname]  -->  ?
    my ($self, $typename) = @_;
    return (exists $self->{'parents'}{$typename} and ! $self->{'parents'}{$typename}) unless ref $typename;
    return 0 unless ref $typename eq 'ARRAY' and @$typename == 2;
    exists $self->{'parents'}{$typename->[0]} and $self->{'parents'}{$typename->[0]} eq $typename->[1];
}
sub check_data     { $_[0]->{'coderef'}->($_[1], $_[2]) } # _ $val $param    -->  ~errormsg
################################################################################

2;

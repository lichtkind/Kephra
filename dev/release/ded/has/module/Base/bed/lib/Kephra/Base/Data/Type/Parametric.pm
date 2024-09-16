use v5.18;
use warnings;
use feature "switch";
no warnings 'experimental::smartmatch';

# serializable data type checks properties of a value and its relation to a second (parameter)
# example:     valid index (type) of an actual array (parameter)
#              { name => 'index', help => 'valid index of array', parent => 'int_pos', # positive integer
#                code =>'return "value $value is out of range" if $value >= @$param', default => 0,
#           parameter =>{name => 'ARRAY', help => 'array reference', code => 'ref $value eq "ARRAY"', default => []}    }   # type is required

package Kephra::Base::Data::Type::Parametric;
our $VERSION = 1.8;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Data::Type::Basic;         my $btype = 'Kephra::Base::Data::Type::Basic';

#### construct $ destruct ######################################################
sub _unhash_arg_ {
    ref $_[0] eq 'HASH'
        ? ($_[0]->{'name'}, $_[0]->{'help'}, $_[0]->{'code'}, $_[0]->{'parameter'}, $_[0]->{'parent'}, $_[0]->{'default'} ) 
        : @_;
}
sub new {   # ~name  ~help  %parameter|.parameter  ~code  .parent - $default    --> .ptype | ~errormsg 
    my $pkg = shift;
    my ($name, $help, $code, $parameter, $parent, $default) = _unhash_arg_(@_);
    my $name_error = Kephra::Base::Data::Type::Basic::_check_name($name);
    return $name_error if $name_error;
    return "need the arguments 'name' (str), 'help' (str), 'parameter' ( basic type object), 'code' (str) ".
        "and maybe 'parent' ($btype) to create parametric type object" unless defined $code and $code and $help ;
    return "parent has to be instance of $btype or ".__PACKAGE__." to create parametric type $name"
        if defined $parent and $parent and ref $parent ne $btype and ref $parent ne __PACKAGE__;

    my $all_parents = [];
    my $checks = [];
    if (ref $parent){
        if (ref $parent eq __PACKAGE__){
            $code = $parent->{'code'}.';'.$code;
            $parameter //= $parent->parameter;
        } else {
            $code = Kephra::Base::Data::Type::Basic::_asm_($name, $parent->source).';'.$code;
        }
        push @$all_parents, $parent->ID, $parent->parents;
        $default //= $parent->default_value;
    }
    return "parametric type '$name' need to get or inherit a default value " unless defined $default;
    return "parametric type '$name' got no 'parameter' type" unless defined $parameter;
    return "parametric type '$name' has to have or inherit a 'parameter' type which has to be a $btype class, not '$parameter'."
        if ref $parameter ne $btype;
    return "parent of parametric type has to to have the same or parent of own parameter type"
           if ref $parent and $parent->kind eq 'param' and $parameter->name ne $parent->parameter->name 
                                                       and not ($parameter->has_parent( $parent->parameter ));

    my $error_start = "type '$name' with parameter '".$parameter->name."'";
    my $source = _compile_( $name, $checks, $code, $parameter );
    my $coderef = eval $source;
    return "$error_start has bad source code : '$source' - could not eval because: $@ !" if $@;
    my $error = $coderef->( $default, $parameter->default_value);
    return "$error_start default value '". $parameter->default_value."' does not pass check - '$source' - because: $error!" if $error;
    bless { name => $name, help => $help, default => $default, parents => $all_parents, parameter => $parameter, 
            code => $code, coderef => $coderef, trustcoderef => eval _compile_with_safe_param_( $name, $checks, $code),  };
}

sub restate {                                        # %state                -->  .ptype | ~errormsg
    my ($pkg, $state) = @_;
    $state->{'parameter'} = Kephra::Base::Data::Type::Basic->restate( $state->{'parameter'} );
    $state->{'coderef'} = eval _compile_( $state->{'name'}, $state->{'checks'}, $state->{'code'}, $state->{'parameter'});
    $state->{'trustcoderef'} = eval _compile_with_safe_param_( $state->{'name'}, $state->{'checks'}, $state->{'code'});
    bless $state;
}
sub state {                                          # _                     -->  %state
    { name=> $_[0]->{'name'}, help=> $_[0]->{'help'}, default=> $_[0]->{'default'}, code=> $_[0]->{'code'}, 
      parents => \@{$_[0]->{'parents'}}, parameter=> $_[0]->{'parameter'}->state() }
}
################################################################################
sub _compile_ {
    my ($name, $check, $code, $parameter) = @_;
    'sub { my ($param, $value) = @_; no warnings "all";'
    . Kephra::Base::Data::Type::Basic::_asm_("$name parameter ".$parameter->name, $parameter->source)
    . '($value, $param)=($param, $value);' . $code . ";return ''}"
}
sub _compile_with_safe_param_ {
    my ($name, $check, $code) = @_;
    'sub { my ($value, $param) = @_; no warnings "all";' . $code . ";return ''}"
}
sub _ID_equal {
    my ($A, $B) = @_;
    return 0 if ref $A ne ref $B or not defined $A or not defined $B; 
    return 1 if not ref $A and $A eq $B;
    return 1 if ref $A eq 'ARRAY' and $A->[0] eq $B->[0] and $A->[1] eq $B->[1];
    0;
}
################################################################################
sub kind           { 'param' }                    # _                        -->  'basic'|'param'
sub name           { $_[0]->{'name'} }            # _                        -->  ~PTname (type name)
sub full_name      { $_[0]->{'name'}.' of '.$_[0]->{'parameter'}->name } # _ -->  ~name.~paramname
sub ID             { [$_[0]->{'name'}, $_[0]->{'parameter'}->ID] }       # _ -->
sub help           { $_[0]->{'help'} }            # _                        -->  ~help
sub code           { $_[0]->{'code'} }            # _                        -->  ~help
#sub source         { $_[0]->{'code'} }            # _                        -->  ~help
sub default_value  { $_[0]->{'default'} }         # _                        -->  $default
sub parameter      { $_[0]->{'parameter'} }       # _                        -->  .parameter
sub parents        { @{$_[0]->{'parents'}} }      # _                        -->  ?? %_parent.name -> :parent:parameter:name
sub has_parent     {                              # _ ~BTname|[~PTname ~BTname] -->  ?
    my ($self, $typename, $paramname) = @_;
    return int @{$self->{'parents'}} > 0 unless defined $typename;
    my $ID = defined $paramname ? [$typename, $paramname] : $typename;
    for ($self->parents){ return 1 if _ID_equal($ID, $_) }
    0;
}
sub ID_equals      {                              # _ $typeID                -->  ?
    my ($self, $ID) = @_;
    (ref $ID eq 'ARRAY' and @$ID == 2 and $ID->[0] eq $self->name and $ID->[1] eq $self->parameter->name ) ? 1 : 0
}
################################################################################
sub checker         { $_[0]->{'coderef'} }         # _                        -->  &check
sub trusting_checker{ $_[0]->{'trustcoderef'} }    # _                        -->  &trusting_check  # when parameter is already type checked
sub check_data      { $_[0]->{'coderef'}->($_[1], $_[2]) } # _ $val $param    -->  '' | ~errormsg
################################################################################

3;

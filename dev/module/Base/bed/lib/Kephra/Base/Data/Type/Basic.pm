use v5.20;
use warnings;
use feature "switch";
no warnings 'experimental::smartmatch';

# serializable data type object that compiles name str, help msg, check code - optional parent name and default value
#                     => coderef (checker) that return error msg or nothing on input
# example      : {name => bool, help=> '0 or 1', code=> '$_[0] eq 0 or $_[0] eq 1', parent=> 'value',  default =>0}
# compiled to  : {check => ['not a reference', 'not ref $_[0]', '0 or 1', '$_[0] eq 0 or $_[0] eq 1'], parents => ['value']
#                 coderef => eval{ sub{ return $_[0] 'failed not a reference' unless not ref $_[0]; ...; 0} } }

package Kephra::Base::Data::Type::Basic;
our $VERSION = 1.6;
use Scalar::Util qw/blessed looks_like_number/;
################################################################################
sub _unhash_arg_ {
    ref $_[0] eq 'HASH' ? ($_[0]->{'name'}, $_[0]->{'help'}, $_[0]->{'code'}, $_[0]->{'parent'}, $_[0]->{'default'}) : @_;
}
sub new {        # ~name ~help ~code - .parent $default --> .type | ~errormsg 
    my $pkg = shift;
    my ($name, $help, $code, $parent, $default) = _unhash_arg_(@_);
    $help //= '';
    $code //= '';
    my $name_error = _check_name($name);
    return $name_error if $name_error;
    return "'parent' of basic type '$name' has to be a hash definition or an instance of ".__PACKAGE__ if defined $parent and ref $parent ne __PACKAGE__ and ref $parent ne 'HASH';
    return "basic type '$name' definition misses 'help' text and 'code' or a 'parent' type object" if $code xor $help or (not $code and not defined $parent);
    my $checks = [];
    my $parents = [];
    push @$checks, $help, $code if $code;
    if (defined $parent){
        $parent = Kephra::Base::Data::Type::Basic->new($parent) if ref $parent eq 'HASH';
        return "can not create type $name, because definition of parent has issue: $parent" unless ref $parent;
        unshift @$checks, @{$parent->source};
        $default //= $parent->default_value;
        push @$parents, $parent->name, @{$parent->parents}; 
    }
    return "basic type '$name' misses 'default' value or a 'parent' type" unless defined $default;
    my $source = _compile_( $name, $checks );
    my $coderef = eval $source;
    return "basic type '$name' checker source 'code' - '$source' - could not eval because: $@ !" if $@;
    my $error = $coderef->( $default );
    return "type '$name' default value '$default' does not pass check - '$source' - because: $error!" if $error;
    bless { name => $name, coderef => $coderef, checks => $checks, default => $default, parents => $parents};
}
################################################################################
sub state             {                           # ._  -->  %state
    {name => $_[0]->{'name'}, parents => [@{$_[0]->{'parents'}}], checks => [@{$_[0]->{'checks'}}], 
    default => $_[0]->{'default'} }
}
sub restate {    # %state                               --> .type | ~errormsg
    my ($pkg, $state) = @_;
    $state->{'coderef'} = eval _compile_( $state->{'name'}, $state->{'checks'} );
    bless $state;
}
#### getter ####################################################################
sub name           { $_[0]->{'name'} }            # _                  -->  ~name
sub parents        { $_[0]->{'parents'} }         # _                  -->  @:parent:name
sub parameter      { '' }                         # _                  -->  ''  # make API compatible
sub has_parent     { $_[1] ~~ $_[0]->{'parents'} }# _  ~parent         -->  ?
sub source         { $_[0]->{'checks'} }          # _                  -->  @checks
sub default_value  { $_[0]->{'default'} }         # _                  -->  $default
sub checker        { $_[0]->{'coderef'} }         # _                  -->  &checker
#### public API ################################################################
sub check_data     { $_[0]->{'coderef'}->($_[1]) }# _  $val            -->  ~errormsg
#### util ######################################################################
sub _check_name  {
    return "type name is not defined" unless defined $_[0];
    return "type name $_[0] has to contain only lower case char, digits and underscore (_)" if  $_[0] =~ /[^a-z0-9_]/;
    return "type name $_[0] has to start with a letter" unless $_[0] =~ /^[a-z]/;
    return "type name $_[0] can not be longer than 16 chracter" if  length $_[0] > 16;
    return "type name $_[0] has to have at least 3 character" if  length $_[0] < 3;
    '';
}
sub _compile_ { 'sub { my( $value ) = @_; no warnings "all";'. _asm_(@_) . "return ''}" }
sub _asm_ {
    my ($name, $checks) = @_;
    my $source = '';
    for (my $i = 0; $i < @$checks; $i+=2) {
        $source .= 'return "value $value'." needed to be of type $name, but failed test: $checks->[$i]\" unless $checks->[$i+1];"
    }
    $source;
}
sub assemble_code { _asm_($_[0]->name, $_[0]->source) }
################################################################################

2;

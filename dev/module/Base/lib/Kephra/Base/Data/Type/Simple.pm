use v5.20;
use warnings;

# serializable data type object that compiles help msg and check code to coderef (checker)
# example      : {name => bool, help=> '0 or 1', code=> '$_[0] eq 0 or $_[0] eq 1', parent=> 'value',  default =>0}
# compiled to  : {check => ['not a reference', 'not ref $_[0]', '0 or 1', '$_[0] eq 0 or $_[0] eq 1'], 
#                 coderef => eval{ sub{ return $_[0] 'failed not a reference' unless not ref $_[0]; ...; 0} } }

package Kephra::Base::Data::Type::Simple;
our $VERSION = 1.2;
use Scalar::Util qw/blessed looks_like_number/;
################################################################################
sub new {        # ~name ~help ~code - .parent $default --> .type | ~errormsg 
    my ($pkg, $name, $help, $code, $parent, $default) = @_;
    if (ref $name eq 'HASH'){
        $default = $name->{'default'} if exists $name->{'default'};
        $parent = $name->{'parent'} if exists $name->{'parent'};
        $code  = $name->{'code'}   if exists $name->{'code'};
        $help  = $name->{'help'}  if exists $name->{'help'};
        $name = exists $name->{'name'} ? $name->{'name'} : undef;
    }
    $help //= '';
    $code //= '';
    return "need type 'name' as first or named argument to create simpe type object" unless defined $name;
    return "parent type object of type $name has to be instance of ".__PACKAGE__ if defined $parent and ref $parent ne __PACKAGE__;
    return "need help text and code or a parent type object to create type $name" if $code xor $help or (not $code and not defined $parent);
    my $checks = [];
    push @$checks, $help, $code if $code;
    if (defined $parent){
        unshift @$checks, @{$parent->get_check_pairs};
        $default //= $parent->get_default_value;
    }
    return "need a default value or at least a parent type to create type $name" unless defined $default;
    my $source = _compile_( $name, $checks );
    my $coderef = eval $source;
    return "simpel type '$name' checker source code '$source' could not eval because: $@ !" if $@;
    my $error = $coderef->( $default );
    return "type '$name' default value '$default' does not pass check '$source' because: $error!" if $error;
    bless { name => $name, coderef => $coderef, checks => $checks, default => $default };
}
sub restate {    # %state                               --> .type | ~errormsg
    my ($pkg, $state) = @_;
    $state->{'coderef'} = eval _compile_( $state->{'name'}, $state->{'checks'} );
    bless $state;
}
################################################################################
sub _compile_ { 'sub { my ($value) = @_; no warnings "all";'. _asm_(@_) . "return ''}" }
sub _asm_ {
    my ($name, $checks) = @_;
    my $source = '';
    for (my $i = 0; $i < @$checks; $i+=2){
        $source .= 'return "value $value'." needed to be of type $name, but failed test: $checks->[$i]\" unless $checks->[$i+1];"
    }
    $source;
}
sub assemble_code { _asm_($_[0]->get_name, $_[0]->get_check_pairs) }
################################################################################
sub state {                                       # .type                 -->  %state
    { name => $_[0]->{'name'}, checks => [@{$_[0]->{'checks'}}], default => $_[0]->{'default'} }
}
sub get_name          { $_[0]->{'name'} }            # .type                 -->  ~name
sub get_check_pairs   { $_[0]->{'checks'} }          # .type                 -->  @checks
sub get_default_value { $_[0]->{'default'} }         # .type                 -->  $default
sub get_checker       { $_[0]->{'coderef'} }         # .type                 -->  &checker
################################################################################
sub check             { $_[0]->{'coderef'}->($_[1]) }# .type $val            -->  ~errormsg
################################################################################

1;

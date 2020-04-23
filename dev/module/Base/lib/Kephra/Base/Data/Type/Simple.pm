use v5.20;
use warnings;

# serializable data type object that compiles help msg and check code to coderef (checker)
# example      : {name => bool, help=> '0 or 1', code=> '$_[0] eq 0 or $_[0] eq 1', parent=> 'value',  default =>0}
# compiled to  : {check => ['not a reference', 'not ref $_[0]', '0 or 1', '$_[0] eq 0 or $_[0] eq 1'], 
#                 coderef => eval{ sub{ return $_[0] 'failed not a reference' unless not ref $_[0]; ...; 0} } }
package Kephra::Base::Data::Type::Simple;
our $VERSION = 0.1;
use Scalar::Util qw/blessed looks_like_number/;
################################################################################
sub new {
    my ($pkg, $name, $help, $code, $default, $parent) = @_;
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
    return "parent type object of $name has to be instance of ".__PACKAGE__ if defined $parent and ref $parent ne __PACKAGE__;
    return "need help text and code or a parent type object to create type $name" if $code xor $help or (not $code and not defined $parent);
    my $check = [];
    push @$check, $help, $code if $code;
    if (defined $parent){
        unshift @$check, @{$parent->get_check_pairs};
        $default //= $parent->get_default_value;
    }
    return "need a default value or at least a parent type to create type $name" unless defined $name;
    my $source = _compile_( $name, $check );
    my $coderef = eval $source;
    return "type $name checker source code '$source' could not eval because: $@ !" if $@;
    my $error = $coderef->( $default );
    return "type $name default value '$default' does not pass check because: $error!" if $error;
    bless { name => $name, coderef => $coderef, check => $check, default => $default };
}
sub restate {                                     # %state                -->  .type | ~errormsg
    my ($pkg, $state) = @_;
    $state->{'coderef'} = eval _compile_( $state->{'name'}, $state->{'check'} );
    bless $state;
}
sub _compile_ {
    my ($name, $check) = @_;
    no warnings "all";
    my $source = 'sub { ';
    for (my $i = 0; $i < @$check; $i+=2){
        $source .= 'return "value $_[0]'." needed to be of type $name, but failed test: $check->[$i]\" unless $check->[$i+1];";
    }
    $source . "return ''}";
}
################################################################################
sub state {                                       # .type                 -->  %state
    { name => $_[0]->{'name'}, check => [@{$_[0]->{'check'}}], default => $_[0]->{'default'} }
}
sub get_name          { $_[0]->{'name'} }         # .type                 -->  ~name
sub get_check_pairs   { $_[0]->{'check'} }        # .type                 -->  @check
sub get_default_value { $_[0]->{'default'} }      # .type                 -->  $default
################################################################################
sub check        { $_[0]->{'coderef'}->($_[1]) } # .type $val            -->  ~errormsg
################################################################################

1;

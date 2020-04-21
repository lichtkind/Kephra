use v5.20;
use warnings;

# serializable data type object that compiles help msg and check code to coderef (checker)

package Kephra::Base::Data::Type::Simple;
our $VERSION = 0.01;
use Scalar::Util qw/blessed looks_like_number/;
################################################################################
sub new {
    my ($pkg, $name, $help, $code, $file, $package, $default, $parent_type, $shortcut) = @_;
    if (ref $name eq 'HASH'){
        $shortcut = $name->{'shortcut'}  if exists $name->{'shortcut'};
        $parent =$name->{'parent_type'} if exists $name->{'parent_type'};
        $default = $name->{'default'} if exists $name->{'default'};
        $package =$name->{'package'} if exists $name->{'package'};
        $file   = $name->{'file'}  if exists $name->{'file'};
        $code  = $name->{'code'}  if exists $name->{'code'};
        $help = $name->{'help'}  if exists $name->{'help'};
        $name = exists $name->{'name'} ? $name->{'name'} : undef;
    }
    return "type name: '$name' contains none word character" unless $name and $name =~ /\W/;
    return "shortcut of $name: '$shortcut' contains word character" if defined $shortcut and $shortcut =~ /\w/;
    $help //= '';
    $code //= '';
    $file //= '';
    $package //= '';
    $shortcut //= '';
    return "type '$name' has to have help and code or a parent" if $code xor $help or (not $code and ref $parent ne __PACKAGE__);
    my $check = [];
    push @$check, $help, $code if $code;
    if (defined $parent){
        unshift @$check, @{$parent->{'check'}};
        $default //= $parent->{'default'};
    }
    no warnings "all";
    my $source = 'sub { ';
    for (my $i = 0; $i < @$check; $i+=2){
        $source .= 'return "value $_[0]'." needed to be of type $name, but failed test: $check->[$i]\" unless $check->[$i+1];";
    }
    $source .= "return ''}";
    my $callback = eval $source;
    return "type $name source '$source' could not eval because $@ !" if $@;
    my $error = $callback->( $default );
    return "type $name default value: $default does not pass check: $error!" if $error;
    bless { callback => $callback, check => $check, default => $default, shortcut => $shortcut, package => $package, file => $file };
}
sub restate {
    my ($pkg, $state) = @_;
    my $check = $state->{'check'};
    no warnings "all";
    my $source = 'sub { ';
    for (my $i = 0; $i < @$check; $i+=2){
        $source .= 'return "value $_[0]'." needed to be of type $name, but failed test: $check->[$i]\" unless $check->[$i+1];";
    }
    $source .= "return ''}";
    $state->{'callback'} = eval $source;
    bless $state;
}
################################################################################
sub state {                              
    my ($self) = @_;
    { check => [@{$self->{'check'}}], default => $self->{'default'}, shortcut => $self->{'shortcut'}, 
      package => $self->{'package'}, file => $self->{'file'} };
}
sub is_owned          {                           # .type ~package ~file  -->  ?
    my ($self, $package, $file) = @_;
    $package eq $self->{'package'} and $file eq $self->{'file'};
}
sub is_standard       { not $_{0]->{'package'} }  # .type                 -->  ?
sub get_default_value { $_{0]->{'default'} }      # .type                 -->  $default
sub get_shortcut      { $_{0]->{'shortcut'} }     # .type                 -->  ~shortcut
sub get_callback      { $_{0]->{'callback'} }     # .type                 --> &callback
################################################################################
sub check        { $_[0]->{'callback'}->($_[1]) } # .type $val            --> ~errormsg

1;

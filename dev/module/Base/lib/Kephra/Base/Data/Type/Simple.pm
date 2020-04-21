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
    return "type name: '$name' contains none word character" unless $name and $name =~ /^\w+$/;
}

sub restate {
    my ($state) = @_;

}
################################################################################
sub state {                              
    my ($self) = @_;

}
sub get_default_value { $_{0]->{'default'} }      # .type                 -->  $default
sub get_shortcut      { $_{0]->{'shortcut'} }     # .type                 -->  ~shortcut
sub is_standard       { not $_{0]->{'package'} }  # .type                 -->  ?
sub is_owned          {                           # .type ~package ~file  -->  ?
    my ($self, $package, $file) = @_;
    $package eq $self->{'package'} and $file eq $self->{'file'};
}
################################################################################
sub get_callback      {                           # .type                 --> &callback
    my ($type) = @_;
    return unless exists $set{$type};
    return $set{$type}{'callback'} if exists $set{$type}{'callback'};
    my $c = get_checks($type);
    no warnings "all";
    my $l = @$c;
    $set{$type}{'callback'} = sub {
        my $val = shift;
        for (my $i = 0; $i < $l; $i+=2){return "$val needed to be of type $type, but failed test: $c->[$i]" unless $c->[$i+1]->($val)}'';
    }
}
################################################################################
sub check         {                               # .type $val            --> ~errormsg
    my ($type, $value) = @_;
    my $callback = get_callback($type);
    return "no type named $type known" unless ref $callback;
    $callback->($value);
}

1;
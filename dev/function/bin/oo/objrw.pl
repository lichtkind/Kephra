use v5.14;
use warnings;
no warnings 'once';

BEGIN {unshift @INC, '.'}

*{Class::before_new} = sub { 'before_new' };
my $obj = Class->new();
*{Class::after_new} = sub { 'after_new' };
my $obj_next = Class->new();

say '';
say "all methods of Class:";
say "  $_" for sort keys %Class::;

say '';
say 'no such sub' unless defined *{Class::no}{'CODE'};
say 'no such sub' unless defined *{Class::no}{'CODE'};
*{Class::no} = sub {  };
say 'there is a no sub' if defined *{Class::no}{'CODE'};

say '';
say  $obj->method('data');
say  $obj->Method(3);
say  $obj->before_new();


say '';
say  $obj->method(1);
$obj->insert_hook_before('method', 'say 77');
say  $obj->method(1);
$obj->remove_hook_before('method');
say  $obj->method(1);

exit (0);

package Class;
use parent qw(Base);

sub BUILD  {
    my $self = shift;
    $self->{a} = 1;
   # my %n = %{__PACKAGE__.'::'.':E'};
    $self;
}

sub method  { $_[1] }
sub Method  { 'upper case method' }
sub _secret { 'don\'t say' }

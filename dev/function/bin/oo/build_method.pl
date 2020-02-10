#!/usr/bin/perl -w
use v5.14;
no warnings qw/experimental/;
use Scalar::Util qw/blessed/;

# instert method for already created objects

package Class;
sub new { bless {} }

package main;
no strict 'refs';

my $obj = Class->new();

say "string context: $obj";
say "ref           : ",ref $obj;
say "methods       :";
say "    - $_" for keys *{"Class::"}{HASH};
say '-'x70;
say 'insert method';
*{"Class::one"} = sub {1};
say '-'x70;
say "here should be a 1: ",$obj->one();
say "methods :";
say "    - $_" for keys %{*{"Class::"}{HASH}};

__END__

package Class;
sub new {
    my ($pkg, $var) = (shift, 3);
    bless \$var, $pkg;
}

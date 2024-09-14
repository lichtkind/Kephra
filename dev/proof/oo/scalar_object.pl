#!/usr/bin/perl -w
use v5.14;
use warnings;
use Scalar::Util qw/blessed/;

package Class;
sub new {
    my ($pkg, $var) = (shift, 3);
    bless \$var, $pkg;
}

package main;

my $obj = Class->new();
say "string context: $obj";
say "content value: $$obj";
say "ref obj: ",ref $obj;
say "blessed obj: ",blessed $obj;
say '-'x70;
say 'change content';
$$obj = 4;
say '-'x70;
say $obj;
say $$obj;
say ref $obj;
say blessed $obj;

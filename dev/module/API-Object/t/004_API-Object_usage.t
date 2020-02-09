#!/usr/bin/perl -w
use v5.14;
use warnings;
use Scalar::Util qw(blessed);
use Test::More tests => 38;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::API::Object;

my (@warning, @error, @note, @report);
my ($class, $item_class, @a) = ('Kephra::API::Object', 'TestClass');
no strict 'refs';
no warnings 'redefine';
*{$class.'::error'}   = sub {push @error,  shift; undef };
*{$class.'::warning'} = sub {push @warning,shift; undef };
*{$class.'::note'}    = sub {push @note,   shift; undef };
*{$class.'::report'}  = sub {push @report, shift; undef };
use strict;
use warnings;

# method checks
my $obj = Good->new(5);
is( ref $obj,                             'Good', "could inherit from $class");
is( $obj->{init},                              1, "BUILD method was called");
is( $obj->{para},                              5, "BUILD method got parameter");
is( ref Bad->new(),                           '', "could not inherit from $class because of missing method");
like( pop(@error),             qr/misses method/, 'correct error message for missing method');

# cloning with noneref
my $clone = $obj->clone();
is( ref $clone,                         ref $obj, "could clone an object");
isnt( $clone,                               $obj, "clone has different ref");
is( $clone->{para},                 $obj->{para}, "did clone values");
$obj->set(7);
is( $obj->get(),                              7, "set value in object");
is( $clone->get(),                            1, "setter in one object does not effect another object");

# cloning HASH
$obj->set({ 1 => 2, 3 => 4});
$clone = $obj->clone();
is( ref $clone->get(),                   'HASH', "HASH ref was cloned");
is( scalar keys %{$clone->get()},             2, "HASH was cloned with right length");
is( $clone->get()->{1},                       2, "first HASH value is right");
is( $clone->get()->{3},                       4, "second HASH value is right");
$obj->get()->{1} = 22;
is( $clone->get()->{1},                       2, "cloned HASH value is independent");

# ARRAY
$obj->set([ 5, 6 ]);
$clone = $obj->clone();
is( ref $clone->get(),                  'ARRAY', "ARRAY ref was cloned");
is( scalar keys @{$clone->get()},             2, "ARRAY was cloned with right length");
is( $clone->get()->[0],                       5, "first ARRAY value is right");
is( $clone->get()->[1],                       6, "second ARRAY value is right");
$obj->get()->[1] = 25;
is( $clone->get()->[0],                       5, "first ARRAY value is independent");

# SCALAR
$obj->set( \7 );
$clone = $obj->clone();
is( ref $clone->get(),                 'SCALAR', "SCALAR ref was cloned");
is( ${$clone->get()},                         7, "SCALAR ref value is right");
my $val = 9;
$obj->set(\$val);
is( ${$clone->get()},                         7, "SCALAR ref value is independent");
my $ref = $obj->get();
$$ref = 11;
is( ${$obj->get()},                          11, "SCALAR ref value has changed in original");
is( $val,                                    11, "SCALAR ref value has changed in original memory cell");
is( ${$clone->get()},                         7, "SCALAR ref value is still independent");

# REF
$val = 8;
$obj->set( \\$val );
$clone = $obj->clone();
is( ref $clone->get(),                    'REF', "REF ref was cloned");
is( $${$clone->get()},                        8, "can get to referenced value in clone");
$val = 12;
is( $${$obj->get()},                         12, "original behind REF has changed");
is( $${$clone->get()},                        8, "clone behind REF has not changed");

# VSTRING
$val = v5.22;
$obj->set( \$val );
$clone = $obj->clone();
is( ref $clone->get(),                'VSTRING', "VSTRING ref was cloned");
is( ${$clone->get()},                     v5.22, "VSTRING value correct");
$val = v5.18;
is( ${$obj->get()},                       v5.18, "original VSTRING has changed");
is( ${$clone->get()},                     v5.22, "clone behind VSTRING ref has not changed");

# OBJ
$obj->set($clone);
$clone = $obj->clone();
is( ref $obj->get(),          ref $clone->get(), "could clone an attribute object");
isnt( $obj->get(),                $clone->get(), "cloned attribute object is different");
$obj->get()->set(2);
$clone->get()->set(9);
is( $obj->get()->get(),                       2, "attribute object works");
is( $clone->get()->get(),                     9, "cloned attribute object works indepenently");


package Good;
use parent qw(Kephra::API::Object);
sub BUILD   { $_[0]->{val} = 1; $_[0]->{init} = 1; $_[0]->{para} = $_[1]; $_[0] }
sub set     { $_[0]->{val} = $_[1] }
sub get     { $_[0]->{val} }
sub status  { }

package Bad;
use parent qw(Kephra::API::Object);
sub status {}

exit 0;
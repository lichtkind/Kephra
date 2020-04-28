#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Parametric;
use Test::More tests => 1;

sub simple_type { Kephra::Base::Data::Type::Simple->new(@_) }
sub para_type { Kephra::Base::Data::Type::Parametric->new(@_) }

my $Tval = simple_type('value', 'not a reference', 'not ref $value', undef, '');
my $Tint = simple_type('int', 'integer number', 'int $value eq $value', $Tval, 0);
my $Tpint = simple_type('pos_int', 'positive integer', '$value >= 0', $Tint);
my $Tarray = simple_type('ARRAY', 'array reference', 'ref $value eq "ARRAY"', undef, []);
my $class = 'Kephra::Base::Data::Type::Parametric';

my $Tindex_type = para_type('index', 'valid index of array', {name => 'array', type => $Tarray, default => [1]}, 'return "value $value is out of range" if $value >= @$param', $Tpint, 0);
say $Tarray->check([]), '[]';
say $Tpint->check(0), '0';
say $Tindex_type;
is ( ref $Tindex_type, $class,                'created first prametric type object');

exit 0;

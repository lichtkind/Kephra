#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 22;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Definition::Attribute;
sub mk_attr_def {Kephra::Base::Class::Definition::Attribute->new(@_)}

my $dclass = 'Kephra::Base::Class::Definition::Attribute::Data';
my $lclass = 'Kephra::Base::Class::Definition::Attribute::Delegating';
my $wclass = 'Kephra::Base::Class::Definition::Attribute::Wrapping';

my $def = mk_attr_def('C');
is( ref $def,                                 $dclass,        'created data attribute');


exit 0;

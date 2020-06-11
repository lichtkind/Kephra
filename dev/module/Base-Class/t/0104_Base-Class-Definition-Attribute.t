#!/usr/bin/perl -w
use v5.16;
use warnings;
use experimental qw/switch/;
use Test::More tests => 5;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Definition::Attribute;
sub mk_attr_def {Kephra::Base::Class::Definition::Attribute->new(@_)}

my $dclass = 'Kephra::Base::Class::Definition::Attribute::Data';
my $lclass = 'Kephra::Base::Class::Definition::Attribute::Delegating';
my $wclass = 'Kephra::Base::Class::Definition::Attribute::Wrapping';

my $req = {name => 'name', help => 'helptext', build => 'code'};

is( ref mk_attr_def('name', {%$req, get => 'get', type => 'int'}),       $dclass,             'created data attribute');
is( ref mk_attr_def('name', {%$req, auto_get => 'get', type => 'int'}),       $dclass,        'created data attribute with autogenerated getter');
is( ref mk_attr_def('name', {%$req, delegate => 'del', class => 'int', build=>[]}), $lclass,  'created delegating attribute');
is( ref mk_attr_def('name', {%$req, auto_delegate => 'del', class => 'int', build=>[]}), $lclass,  'created delegating attribute with autogenerated delegator');
is( ref mk_attr_def('name', {%$req, wrap => 'get', class => 'int'}),     $wclass,             'created wrapping attribute');

exit 0;

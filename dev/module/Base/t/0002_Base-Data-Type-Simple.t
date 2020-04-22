#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}

use Kephra::Base::Data::Type::Simple;
use Test::More tests => 55;

my $pkg = 'Kephra::Base::Data::Type::Simple';
my $value = Kephra::Base::Data::Type::Simple->new('value','not a reference', 'not ref $_[0]', '');
is( ref $value, $pkg,               'created first type object "value"');
is( $value->get_name, 'value',      'remembered type name');
is( $value->get_default_value, '',  'remembered default value');
is( $value->check(3), '',           'checker of type "value" has true positive result');
ok( $value->check([]),              'checker of type "value" has true negative result');

my $state = $value->state;
is( ref $state, 'HASH',              'state dump is hash ref');
my $vclone = Kephra::Base::Data::Type::Simple->restate($state);
is( ref $vclone, $pkg,              'recreated object for type "value"');
is( $vclone->get_name, 'value',     'type name is correct');
is( $vclone->get_default_value, '', 'types default value is correct');
is( $vclone->check(3), '',          'checker of type "value" clone has true positive result');
ok( $vclone->check([]),             'checker of type "value" clone has true negative result');

my $bool = Kephra::Base::Data::Type::Simple->new('bool','0 or 1', '$_[0] eq 0 or $_[0] eq 1', 0, $value);
is( ref $bool, $pkg,               'created child type object bool');
is( $bool->get_name, 'bool',       'remembered type name');
is( $bool->get_default_value, 0,   'remembered default value');
is( $bool->check(0), '',           'checker of type "bool" has true positive result');
is( $bool->check(1), '',           'checker of type "bool" has second true positive result');
ok( $bool->check([]),              'checker of type "bool" has true negative result');
ok( $bool->check(5),               'checker of type "bool" has second true negative result');
ok( $bool->check('--'),            'checker of type "bool" has third true negative result');

my $bclone = Kephra::Base::Data::Type::Simple->restate( $bool->state );
is( ref $bclone, $pkg,             'recreated child type object bool');
is( $bclone->get_name, 'bool',     'remembered type name');
is( $bclone->get_default_value, 0, 'remembered default value');
is( $bclone->check(0), '',         'checker of type "bool" clone has true positive result');
is( $bclone->check(1), '',         'checker of type "bool" clone has second true positive result');
ok( $bclone->check([]),            'checker of type "bool" clone has true negative result');
ok( $bclone->check(5),             'checker of type "bool" clone has second true negative result');
ok( $bclone->check('--'),          'checker of type "bool" clone has third true negative result');

my $str = Kephra::Base::Data::Type::Simple->new('str', undef, undef, undef, $value);
is( ref $str, $pkg,                'created rename type object str with undef help and code');
is( $str->get_name, 'str',         'remembered type str');
is( $str->get_default_value, '',   'inherited default value correctly');
is( $str->check('-'), '',          'checker of type "str" has true positive result');
is( $str->check(1), '',            'checker of type "str" has second true positive result');
ok( $str->check([]),               'checker of type "str" has true negative result');

$str = Kephra::Base::Data::Type::Simple->new('str', '', '', undef, $value);
is( ref $str, $pkg,                'created rename type object str with empty help and code');
is( $str->get_name, 'str',         'remembered type str');
is( $str->get_default_value, '',   'inherited default value correctly');
is( $str->check('-'), '',          'checker of type "str" has true positive result');
is( $str->check(1), '',            'checker of type "str" has second true positive result');
ok( $str->check([]),               'checker of type "str" has true negative result');

$bool = Kephra::Base::Data::Type::Simple->new({name => 'bool', help => '0 or 1', code => '$_[0] eq 0 or $_[0] eq 1',default => 0, parent => $value});
is( ref $bool, $pkg,               'created child type object bool with argument hash');
is( $bool->get_name, 'bool',       'remembered type name');
is( $bool->get_default_value, 0,   'remembered default value');
is( $bool->check(0), '',           'checker of type "bool" has true positive result');
is( $bool->check(1), '',           'checker of type "bool" has second true positive result');
ok( $bool->check([]),              'checker of type "bool" has true negative result');
ok( $bool->check(5),               'checker of type "bool" has second true negative result');
ok( $bool->check('--'),            'checker of type "bool" has third true negative result');

exit 0;

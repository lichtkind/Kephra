#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/smartmatch/;
BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}


package TypeTester; 
use Kephra::Base::Data::Type::Standard;

my (%pos_val, %pos_param_val, %neg_val, %neg_param_val, $tcc);

BEGIN {
    %pos_val = (value => [1, 'str', [], sub{}],
                bool => [0,1],
                str => ['', ' ', '#'],
                str_uc => ['C', ' ', '/'],
                str_lc => ['b', ' ', '-'],
                word => ['Tree'],
                num => [-44.56,0,1.11,-23E-4,100_00, 22E13],
                num_pos => [0,1.11, 100_00, 22E13],
                int => [-10,0,23,100_00, 22E13],
                int_pos => [0,23,100_00, 22E13],
                type_name => [qw/num int str/],
                );
    %neg_val = (value => [undef],
                bool => [-1,2,'',[]],
                int   => [1.1, '--', undef, []],
                type_name => ['blub']);
    %pos_param_val = (index     => {array  =>  [ [0,[1,2]], [2,[1,2,3]],    ]},
                      typed_ref => {ref_name => [ [[],'ARRAY'], [{},'HASH'], ]},
    );
    %neg_param_val = (index => {array =>   [ [-1,[1,2]], [2,[]]  ]});
    for (values %pos_val, values %neg_val) { $tcc += @$_ }
    for (values %pos_param_val, values %neg_param_val) {for (values %$_) {$tcc += @$_}}
}

use Test::More tests =>  3 + $tcc +
     @Kephra::Base::Data::Type::Standard::basic_type_definitions +
     @Kephra::Base::Data::Type::Standard::parametric_type_definitions +
     @Kephra::Base::Data::Type::Standard::forbidden_shortcuts +
     keys(%Kephra::Base::Data::Type::Standard::basic_type_shortcut) +
     keys(%Kephra::Base::Data::Type::Standard::parametric_type_shortcut) 
;


Kephra::Base::Data::Type::Standard::init_store();
my $store = Kephra::Base::Data::Type::Standard::get_store();

is( ref $store,        'Kephra::Base::Data::Type::Store',    'got the official store of the standard types');
is( $store->is_open,                                   0,    'the store is closed');

is( $store->is_type_known( $_->{'name'} ), 1,    "basic type '$_->{name}' was created") 
    for @Kephra::Base::Data::Type::Standard::basic_type_definitions;;
     
is( $store->is_type_known( $_->{'name'}, $_->{'parameter'}{'name'}), 1,  "parametric type $_->{name} of $_->{parameter}{name} was created")
    for @Kephra::Base::Data::Type::Standard::parametric_type_definitions;

my @fscd = sort @Kephra::Base::Data::Type::Standard::forbidden_shortcuts;
my @fsc = $store->list_forbidden_shortcuts;

is( int @fscd,                                  int @fsc,    'right amount of forbidden type shortcuts');
is( $fscd[$_],                                  $fsc[$_],    "type shortcut $fscd[$_] forbidden ") for 0 .. $#fscd;

my %sc = %Kephra::Base::Data::Type::Standard::basic_type_shortcut;
is( $store->resolve_shortcut('basic', $sc{$_}),       $_,    "shortcut of basic type $_ is $sc{$_}") for keys %sc;
%sc = %Kephra::Base::Data::Type::Standard::parametric_type_shortcut;
is( $store->resolve_shortcut('param', $sc{$_}),       $_,    "shortcut of parametric type $_ is $sc{$_}") for keys %sc;

for my $type (keys %pos_val){
    is( $store->check_basic_type($type, $_),  '', "value $_ is of basic type '$type'") for @{$pos_val{$type}};
}
for my $type_name (keys %pos_param_val){
    for my $param_name (keys %{$pos_param_val{$type_name}}){
        for my $val (@{$pos_param_val{$type_name}{$param_name}}){
            is( $store->check_param_type($type_name, $param_name, @$val),  '', "values $val->[0] and $val->[1] fit the parametric type $type_name of $param_name");
        }
    }
}
no warnings;
for my $type (keys %neg_val){
    ok( $store->check_basic_type($type, $_),      "value $_ is not of basic type '$type'") for @{$neg_val{$type}};
}
for my $type_name (keys %neg_param_val){
    for my $param_name (keys %{$neg_param_val{$type_name}}){
        for my $val (@{$neg_param_val{$type_name}{$param_name}}){
            ok( $store->check_param_type($type_name, $param_name, @$val),  "values $val->[0] and $val->[1] do not fit the parametric type $type_name of $param_name");
        }
    }
}

__END__

is( check_type('value',1),             '', 'recognize 1 as value');
is( check_type('value','1'),           '', 'even "1" is a value');
is( check_type('value',0),             '', 'recognize 0 as value');
is( check_type('value',''),            '', 'recognize empty string as value');
is( check_type('value','d'),           '', 'recognize letter value');
is( check_type('value',[]),            '', 'recognize that ref is a value');
ok( check_type('value',undef),             'only undef is not a value');

is( check_type('no_ref', 1),           '', 'recognize 1 as value');
is( check_type('no_ref', 2.3E2),       '', 'recognize sci real as value');
is( check_type('no_ref', 0),           '', 'recognize 0 as value');
is( check_type('no_ref', 'd'),         '', 'recognize string as value');
is( check_type('no_ref', ''),          '', 'recognize empty string as value');
ok( check_type('no_ref',[]),               'ARRAY is a ref');
ok( check_type('no_ref',{}),               'HASH is a ref');
ok( check_type('no_ref',sub {}),           'CODE is a ref');
ok( check_type('no_ref',qr//),             'Regex is a ref');

is( check_type('bool',1),              '', 'recognize boolean value true');
is( check_type('bool',0),              '', 'recognize boolean value false');
ok( check_type('bool',''),                 'empty is not boolean');
ok( check_type('bool','der'),              'string is not boolean');
ok( check_type('bool',2),                  'int is not boolean');
ok( check_type('bool',2.3),                'float is not boolean');
ok( check_type('bool',[]),                 'ref is not boolean');
is( Kephra::Base::Data::Type::Standard::get('bool')->get_default_value(), 0, 'got default bool');

is( check_type('num',22),              '', 'recognize an integer as a number');
is( check_type('num',1.5),             '', 'recognize small float as number');
is( check_type('num',0.1e-5),          '', 'recognize scientific number');
is( check_type('num',1000_00),         '', 'recognize underscore seperated number');
ok( check_type('num','das'),               'string is not a number');
ok( check_type('num', sub{}),              'coderef is not a number');
is( Kephra::Base::Data::Type::Standard::get('num')->get_default_value(), 0, 'got default number');

is( check_type('num_pos',1.5),         '', 'recognize positive number');
is( check_type('num_pos',0),           '', 'zero is positive number');
ok( check_type('num_pos',-1.5),            'a negative is not a positive number');
ok( check_type('num_pos','das'),           'string is not a positive number');

is( check_type('int',  5),             '', 'recognize integer');
is( check_type('int',-12),             '', 'recognize negative integer');
is( check_type('int',1_2e12),          '', 'recognize huge integer');
ok( check_type('int',1.5),                 'real is not an integer');
ok( check_type('int','das'),               'string is not an integer');
ok( check_type('int',{}),                  'hash ref is not an integer');

is( check_type('int_pos',1),           '', 'recognize positive int');
is( check_type('int_pos',0),           '', 'zero is positive int');
ok( check_type('int_pos',-1),              'a negative is not a positive int');
ok( check_type('int_pos','das'),           'string is not a positive int');

is( check_type('int_spos',1),          '', 'one is a stricly positive number');
ok( check_type('int_spos',0),              'zero is not a stricly positive number');

is( check_type('str', 'das'),          '', 'recognize string');
is( check_type('str', 5),              '', 'numbers can be strings');
ok( check_type('str', {}),                 'ref ist not a string');


is( check_type('str_ne','das'),        '', 'recognize none empty string');
ok( check_type('str_ne', ''),              'this is not a none empty string');

is( check_type('str_uc', 'DAS'),       '', 'recognize upper case string');
ok( check_type('str_uc', 'DaS'),           'this is not an upper case string');
is( Kephra::Base::Data::Type::Standard::get('str_uc')->get_default_value(), 'A', 'got default upper case string');

is( check_type('str_lc', 'das'),       '', 'recognize lower case string');
ok( check_type('str_lc', 'DaS'),           'this is not an lower case string');

is( check_type('num',  1.5),           '', 'recognize number');
is( check_type('num_pos', 1.5),        '', 'recognize positive number');
is( check_type('int',     5),          '', 'recognize integer');
is( check_type('int_pos', 5),          '', 'recognize positive integer');


my @type = guess_type(5);
ok( !('bool' ~~ \@type),  '5 is not an boolean');
ok( 'int' ~~ \@type,      '5 is an integer');
ok( 'int_pos' ~~ \@type,  '5 is a positive integer');
ok( 'int_spos' ~~ \@type, '5 is a strictly positive integer');
ok( 'num' ~~ \@type,      '5 is a number');
ok( 'num_pos' ~~ \@type,  '5 is a positive number');
ok( 'str_ne' ~~ \@type,   '5 is none empty string');
ok( 'any' ~~ \@type,      '5 is anything');


@type = guess_type(0);
ok( 'bool' ~~ \@type,     '0 is a boolean');
ok( 'int' ~~ \@type,      '0 is an integer');
ok( 'int_pos' ~~ \@type,  '0 is a positive integer');
ok( 'num' ~~ \@type,      '0 is a number');
ok( 'num_pos' ~~ \@type,  '0 is a positive number');
ok( 'str_ne' ~~ \@type,   '0 is none empty string');
ok( 'any' ~~ \@type,      '0 is a value');

@type = guess_type('');
ok( !('bool' ~~ \@type),  'empty string is not a boolean');
ok( !('int' ~~ \@type),   'empty string is not an integer');
ok( !('num' ~~ \@type),   'empty string is not a number');
ok( !('str_ne' ~~ \@type),'not empty string');
ok( 'any' ~~ \@type,      'empty string is a value');

@type = Kephra::Base::Data::Type::Standard::list_names();
ok( ('bool' ~~ \@type),  'bool type is known, list works');
ok( ('num' ~~ \@type),   'num type is known, list works');
ok( ('int' ~~ \@type),   'int type is known, list works');
ok( ('any' ~~ \@type),   'any type is known, list works');


exit 0;


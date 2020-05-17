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
                no_ref => [0,1,'--'],
                bool => [0,1],
                num => [-44.56,0,1.11,-23E-4,100_00, 22E13],
                num_pos => [0,1.11, 100_00, 22E13],
                num_spos => [1.11, 100_00, 22E13],
                int => [-10,0,23,100_00, 22E13],
                int_pos => [0,23,100_00, 22E13],
                int_spos => [23,100_00, 22E13],
                str => ['', ' ', '#', 'der'],
                str_ne  => ['die das'],
                str_uc => ['C', ' ', '/'],
                str_lc => ['b', ' ', '-'],
                word => ['Tree','Die_das2'],
                arg_name => ['tree','die_das2'],
                type_name => [qw/num int str/],
                array_ref => [[], [[]]],
                hash_ref => [{}, {1=>{}}],
                any_ref => [[],{}, sub{}, bless{}],
    );
    %neg_val = (value => [undef],
                no_ref => [[],{},sub{}],
                bool => [-1,2,'',[], undef],
                num  => ['das', '', undef, []],
                num_pos => [-220.1, '', undef, []],
                num_spos => [-22.2, 0, '', undef, []],
                int     => [1.1, '--', undef, {}],
                int_pos  => [-3, 23.3e-3, '--', undef, []],
                int_spos  => [0, -3, 1.1e-1, '--', undef, []],
                str   => [ qr//, undef, []],
                str_ne  => ['', qr//, undef, []],
                str_uc => ['c', '', [], undef],
                str_lc => ['V', '', [], undef ],
                word  => ['die das', [], undef],
                arg_name => ['Tree','die das2'],
                type_name => ['blub'],
                array_ref => [{}, '', undef],
                hash_ref => [[], '', undef],
                code_ref => [[], {}, 4, '', undef],
                object => [[], {}, 4, '', undef],

    );
    %pos_param_val = (index     => {array  =>  [ [0,[1,2]], [2,[1,2,3]],    ]},
                      typed_ref => {ref_name => [ [[],'ARRAY'], [{},'HASH'], ]},
                    typed_array => {type_name => [ [[2,4,-7,0],'int'], [['-', '', 'was'],'str'], ]},
                     typed_hash => {type_name => [ [{1=>2, 7=>0, 3=>-1},'int'], [{1=>' ', 7=>'was', 3=>''},'str'], ]},
    );
    %neg_param_val = (index => {array =>   [ [-1,[1,2]], [2,[]]  ]},
                      typed_ref => {ref_name => [ [{} ,'ARRAY'], [undef, 'HASH'], ]},
                    typed_array => {type_name => [ [[2,4,'das',0],'int'], [[0, '', 22.2],'num'], ]},
                     typed_hash => {type_name => [ [{1=>2, 7=>undef, 3=>-1},'int'], [{1=>' ', 7=>[], 3=>''},'str'], ]},
    );
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

exit 0;


#!/usr/bin/perl -w
use v5.18;
use warnings;
use experimental qw/switch/;
use Test::More tests => 16;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Scope qw/cat_scope_path/;


my @mscopes = Kephra::Base::Class::Scope::method_scopes();
my @scopes = Kephra::Base::Class::Scope::all_scopes();


cmp_ok(@scopes, '>=', 1, 'there are scopes');
cmp_ok(@mscopes, '>=', 1, 'there are method scopes');
cmp_ok(@scopes, '>=', @mscopes, 'just scopes for methods can not be more than all scopes');

my $minc = 1;
$minc = $minc & ($_ ~~ \@scopes) for @mscopes;
ok($minc, 'scopes for methods are included in all scopes');

my $isname = 1;
$isname = $isname & Kephra::Base::Class::Scope::is_scope($_) for @mscopes;
ok($minc, 'all method scopes are recognized as scops');

$isname = 1;
$isname = $isname & Kephra::Base::Class::Scope::is_method_scope($_) for @mscopes;
ok($minc, 'all method scopes are recognized as such');

$isname = 1;
$isname = $isname & Kephra::Base::Class::Scope::is_scope($_) for @scopes;
ok($minc, 'all scopes are recognized as such');


my $same = 1;
for my $ascope (@mscopes){
    for my $bscope (@mscopes){
        if ($ascope eq $bscope){ 
            $same = $same & Kephra::Base::Class::Scope::is_first_tighter($ascope, $bscope);
            $same = $same & Kephra::Base::Class::Scope::is_first_tighter($bscope, $ascope);
        }
    }
}
ok($same, 'same scope is counted as tighter');

my $diff = 1;
for my $ascope (@mscopes){
    for my $bscope (@mscopes){
        unless ($ascope eq $bscope){ 
            $diff = $diff & (Kephra::Base::Class::Scope::is_first_tighter($ascope, $bscope) xor
                             Kephra::Base::Class::Scope::is_first_tighter($bscope, $ascope)    );
        }
    }
}
ok($diff, 'only one of two different scopes can be tighter');

ok ( not (Kephra::Base::Class::Scope::cat_scope_path('public')), 'construct_path needs more than one argument');
ok ( Kephra::Base::Class::Scope::cat_scope_path('public', 'class') eq 'class', 'construct_path needs two arguments');

is ( Kephra::Base::Class::Scope::cat_scope_path('public', 'class', 'method'), 'class::method', 'public scope is the normal one');
is ( cat_scope_path('public', 'class', 'method'), 'class::method', 'sub cat_scope_path got exported');

ok ( length(cat_scope_path('private', 'class', 'method')) > 13, 'in private scope scope name is added');

is (cat_scope_path('public', 'class', 'method', 'attr'), cat_scope_path('public', 'class', 'method', ),
    'ignore third arg while construct path of method scope');


my $depth = 1;
for my $ascope (@mscopes){
    for my $bscope (@mscopes){
        if (Kephra::Base::Class::Scope::is_first_tighter($ascope, $bscope)){ 
            $depth = $depth & (Kephra::Base::Class::Scope::included_names($ascope, 'c', 'm') <=
                               Kephra::Base::Class::Scope::included_names($bscope, 'c', 'm')    );
        }
    }
}
ok($diff, ' tighter scope inclodes less othr scopes');

exit 0;

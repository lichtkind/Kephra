use v5.18;
use warnings;
use experimental qw/switch/;
use Test::More tests => 26;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Definition::Scope qw/cat_scope_path/;


my @mscopes = Kephra::Base::Class::Definition::Scope::method_scopes();
my @scopes = Kephra::Base::Class::Definition::Scope::all_scopes();


cmp_ok(@scopes,  '>=', 1, 'there are scope name constants');
cmp_ok(@mscopes, '>=', 1, 'there are method scopes');
cmp_ok(@scopes,  '>=', @mscopes, 'methods scope count is smaller than all scopes');

my $minc = 1;
$minc = $minc & ($_ ~~ \@scopes) for @mscopes;
ok($minc, 'scopes for methods are included in all scopes');

my $isname = 1;
$isname = $isname & Kephra::Base::Class::Definition::Scope::is_scope($_) for @mscopes;
ok($minc, 'all method scopes are recognized as scops');

$isname = 1;
$isname = $isname & Kephra::Base::Class::Definition::Scope::is_method_scope($_) for @mscopes;
ok($minc, 'all method scopes are recognized as such');

$isname = 1;
$isname = $isname & Kephra::Base::Class::Definition::Scope::is_scope($_) for @scopes;
ok($minc, 'all scopes are recognized as such');


my $same = 1;
for my $ascope (@mscopes){
    $same = $same & Kephra::Base::Class::Definition::Scope::is_first_tighter($ascope, $ascope);
}
ok($same, 'same scope is counted as tighter');

my $diff = 1;
for my $ascope (@mscopes){
    for my $bscope (@mscopes){
        unless ($ascope eq $bscope){ 
            $diff = $diff & (Kephra::Base::Class::Definition::Scope::is_first_tighter($ascope, $bscope) xor
                             Kephra::Base::Class::Definition::Scope::is_first_tighter($bscope, $ascope)    );
        }
    }
}
ok($diff, 'only one of two different scopes can be tighter');

my $depth = 1;
for my $ascope (@mscopes){
    for my $bscope (@mscopes){
        if (Kephra::Base::Class::Definition::Scope::is_first_tighter($ascope, $bscope)){ 
            $depth = $depth & (Kephra::Base::Class::Definition::Scope::cat_method_paths($ascope, 'c', 'm') >=
                               Kephra::Base::Class::Definition::Scope::cat_method_paths($bscope, 'c', 'm')    );
        }
    }
}
ok($diff, ' tighter scope includes less othr scopes');


ok ( not (Kephra::Base::Class::Definition::Scope::cat_method_paths('public')), 'cat_method_paths needs more than one argument');
ok ( not (Kephra::Base::Class::Definition::Scope::cat_method_paths('public','class')), 'cat_method_paths needs more than two arguments');
ok ( not (Kephra::Base::Class::Definition::Scope::cat_method_paths('public',1,2,3)), 'cat_method_paths needs less than four arguments');
my @pnames = Kephra::Base::Class::Definition::Scope::cat_method_paths('public', 'class', 'method');
ok (@pnames == 1, 'has only one public method name');
ok ($pnames[0] eq 'class::method', 'and method name is correctly spelled');
my @anames = Kephra::Base::Class::Definition::Scope::cat_method_paths('access', 'class', 'method');
ok ( @anames == 3, 'there is now private and public method name');
ok ($anames[1] eq 'class::.::PRIVATE::method', 'and its correctly spelled');


ok ( not (Kephra::Base::Class::Definition::Scope::cat_attribute_path('class')), 'cat_attribute_path needs more than one argument');
ok ( not (Kephra::Base::Class::Definition::Scope::cat_attribute_path('public',2,3)), 'cat_attribute_path needs less than three arguments');
my $atpath = Kephra::Base::Class::Definition::Scope::cat_attribute_path('class', 'a');
ok ($atpath eq 'class::.::ATTRIBUTE::a', 'and attribute namespace path is correctly spelled');

ok ( not (Kephra::Base::Class::Definition::Scope::cat_arguments_path('class','method')), 'cat_arguments_path needs more than two arguments');
ok ( not (Kephra::Base::Class::Definition::Scope::cat_arguments_path('public',2,3,4)), 'cat_arguments_path needs less than four arguments');
my $argpath = Kephra::Base::Class::Definition::Scope::cat_arguments_path('class', 'm','a');
ok ($argpath eq 'class::.::METHOD::m::ARGUMENT::a', 'and argument namespace path is correctly spelled');

ok ( not (Kephra::Base::Class::Definition::Scope::cat_hook_path('public','class','h')), 'cat_hook_path needs more than three arguments');
ok ( not (Kephra::Base::Class::Definition::Scope::cat_hook_path('public',2,3,4,5)), 'cat_hook_path needs less than five arguments');
my $hpath = Kephra::Base::Class::Definition::Scope::cat_hook_path('class', 'm','ht','hn');
ok ($hpath eq 'class::.::METHOD::m::HOOK::ht::hn', 'and argument namespace path is correctly spelled');

exit 0;

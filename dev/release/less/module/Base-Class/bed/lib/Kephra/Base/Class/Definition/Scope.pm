use v5.20;
use warnings;
use experimental qw/switch/;

# namespace constants, paths & priority logic
# 0101_Base-Class-Definition-Scope.t

package Kephra::Base::Class::Definition::Scope;
our $VERSION = 1.6;

################################################################################
my $prefix   = '.';
my %name     = (attribute => 'ATTRIBUTE', method => 'METHOD', hook => 'HOOK', argument => 'ARGUMENT',
                public => '',   private => 'PRIVATE',  access => 'ACCESS', build => 'BUILD');
my %priority = (public => 1,    private => 2,          access => 3,        build => 4); # 
my @method_scopes = sort {$priority{$a} <=> $priority{$b}} (keys %priority);
my @scopes        = keys %name;
################################################################################
sub all_scopes          { @scopes }
sub is_scope            { exists $name{$_[0]} }
sub method_scopes       { @method_scopes }
sub is_method_scope     { exists $priority{$_[0]} }
sub is_first_tighter    { # compare priority of two method scopes
    return undef unless @_ == 2 and exists $priority{$_[0]} and exists $priority{$_[1]};
    $priority{$_[0]} >= $priority{$_[1]};
}
################################################################################
sub cat_method_paths {
    return unless @_ == 3 and $priority{$_[0]};
    my ($scope, $class, $method) = @_;
    my @pathes;
    $class .= '::';
    for my $mscope (@method_scopes){
        my $c = $name{ $mscope };
         push @pathes, ($c ? "$class$prefix\::$c\::" : $class) . $method;
         return @pathes if $mscope eq $scope;
    }
}
sub cat_hook_path      {return unless @_ == 4; "$_[0]::$prefix\::METHOD::$_[1]::HOOK::$_[2]::$_[3]" }
sub cat_arguments_path {return unless @_ == 3; "$_[0]::$prefix\::METHOD::$_[1]::ARGUMENT::$_[2]" }
sub cat_attribute_path {return unless @_ == 2; "$_[0]::$prefix\::ATTRIBUTE::$_[1]" }
################################################################################

1;

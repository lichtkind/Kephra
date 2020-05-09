use v5.20;
use warnings;
use experimental qw/switch/;

# method namespace constants and their priority logic

package Kephra::Base::Class::Scope;
our $VERSION = 1.5;

################################################################################
my $prefix   = '-';
my %name     = (attribute => 'ATTRIBUTE', method => 'METHOD', hook => 'HOOK', argument => 'ARGUMENT',
                public => '',   private => 'PRIVATE',  access => 'ACCESS', build => 'BUILD');
my %priority = (public => 1,    private => 2,          access => 3,        build => 4); # 
my @method_scopes = map { $name{$_} } sort {$priority{$b} <=> $priority{$a}} (keys %priority);
my @names         = values %name;
################################################################################
#sub is_scope            { $_[0] and exists $name{$_[0]} }
#sub is_method_scope     { $_[0] and exists $priority{$_[0]} }
#sub is_name             { $_[0] and $_[0] ~~ \@names }
sub is_first_tighter    { # compare priority of two method scopes
    return undef unless @_ == 2 and $priority{$_[0]} and $priority{$_[1]};
    $priority{$_[0]} >= $priority{$_[1]};
}
################################################################################
sub cat_method_paths {
    return unless @_ == 3 and $priority{$_[0]};
    my ($scope, $class, $method) = @_;
    my @pathes;
    $class .= '::';
    for my $s (@method_scopes){
         push @pathes, ($s ? "$class$prefix::$s::" : $class) . $method;
         return @pathes if $s eq $name{ $scope };
    }
}
sub cat_hook_path      {return unless @_ == 2; "$_[0]::$prefix::METHOD::$_[1]::HOOK" }
sub cat_argument_path  {return unless @_ == 2; "$_[0]::$prefix::METHOD::$_[1]::ARGUMENT" }
sub cat_attribute_path {return unless @_ == 2; "$_[0]::$prefix::ATTRIBUTE::$_[1]" }
################################################################################

1;

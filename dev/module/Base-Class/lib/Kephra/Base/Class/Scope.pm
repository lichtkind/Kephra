use v5.18;
use warnings;
use experimental qw/switch/;

# method namespace constants and their priority logic

package Kephra::Base::Class::Scope;
our $VERSION = 0.04;
use Exporter 'import';
our @EXPORT_OK = qw/cat_scope_path/;
our %EXPORT_TAGS = (all  => [@EXPORT_OK]);
################################################################################
my $prefix   = '-';
my %name     = (hook => 'HOOK', argument => 'ARGUMENT',attribute => 'ATTRIBUTE',
                public => '',   private => 'PRIVATE',  access => 'ACCESS', build => 'BUILD');
my %priority = (public => 1,    private => 2,          access => 3,        build => 4); # 
my @importance = sort {$priority{$b} <=> $priority{$a}} (keys %priority);
my @names      = values %name;
################################################################################
sub method_scopes       { @importance }
sub all_scopes          { keys %name }

sub is_scope            { $_[0] and exists $name{$_[0]} }
sub is_method_scope     { $_[0] and exists $priority{$_[0]} }
sub is_name             { $_[0] and $_[0] ~~ \@names }

sub is_first_tighter    { # compare priority of two method scopes
    return undef unless @_ == 2 and $priority{$_[0]} and $priority{$_[1]};
    $priority{$_[0]} >= $priority{$_[1]};
}
################################################################################
sub included_names {
    return unless @_ > 1 and $priority{$_[0]};
    my $scope = shift;
    my @names;
    for my $s (@importance){
        push @names, cat_scope_path($s, @_);
        return @names if $s eq $scope;
    }
}
sub cat_scope_path { # create package name for scope of that class
    return unless @_ > 1 and defined $name{$_[0]} and not ($_[0] ~~ \@names);
    my $scope = shift;
    my $c = shift;
    # return if defined $_[0] and $_[0] ~~ \@names; # with prefix there are no method name collisions
    # return if defined $_[1] and $_[1] ~~ \@names;
    $c .= '::'.$prefix.'::'.$name{$scope} if $name{$scope};
    $c .= '::'.$_[0] if $_[0];
    $c .= '::'.$_[1] if $_[1] and not $priority{ $scope };
    $c;
}
################################################################################
1;

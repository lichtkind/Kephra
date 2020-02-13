use v5.18;
use warnings;

# central store for method namespace constants and their priority logic
# Classname::method
# Classname::PRIVATE::methodname          # & ACCESS/BUILD
# Classname::HOOK::method::BEFORE/AFTER
# Classname::ARGUMENT::method::arghashref
# Classname::ATTRIBUTE::attrname::get/set/reset

package Kephra::Base::Class::Scope;
our $VERSION = 0.04;
################################################################################
my %constant = (hook => 'HOOK', argument => 'ARGUMENT',attribute => 'ATTRIBUTE',
                public => '',   private => 'PRIVATE',  access => 'ACCESS', build => 'BUILD');
my %level    = (public => 1,    private => 2,          access => 3,        build => 4);
my @importance = sort {$level{$b} <=> $level{$a}} (keys %level);
################################################################################
sub method_scope_names { @importance }
sub all_scope_names    { keys %constant }
sub is_name            { $_[0] and exists $level{$_[0]} }
sub is_first_tighter   {
    return undef unless @_ == 2 and $level{$_[0]} and $level{$_[1]};
    $level{$_[0]} >= $level{$_[1]};
}
################################################################################
sub included_names {
    return unless @_ > 1 and $level{$_[0]};
    my $scope = shift;
    my @names;
    for my $s (@importance){
        push @names, name($s, @_);
        return @names if $s eq $scope;
    }
}

sub construct_path { # create package name for scope of that class
    return unless @_ > 1 and defined $constant{$_[0]};
    my $scope = shift;
    my $c = shift;
    $c .= '::'.$constant{$scope} if $constant{$scope};
    $c .= '::'.$_[0] if $_[0];
    $c .= '::'.$_[1] if $_[1] and not $level{$_[0]};
    $c;
}
################################################################################
1;

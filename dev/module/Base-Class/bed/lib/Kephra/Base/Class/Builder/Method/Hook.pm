use v5.18;
use warnings;

# code snippets that run before and after a method is called

package Kephra::Base::Class::Builder::Method::Hook;
our $VERSION = 0.01;
use Kephra::Base::Package;
use Kephra::Base::Class::Definition::Scope;
my %type = (BEFORE => 1, AFTER => 1, BEFORE_AND => 1, AND_AFTER => 1);
my %name = (BEFORE => 1, AFTER => 1, BEFORE_AND_AFTER => 1);
################################################################################
sub create_anchor {
    my ($class, $method) = @_;
    return if has_anchor($method);
    my $ret;
    for my $slot (keys %type){
        my $name = Kephra::Base::Class::Scope::name('hook', $class, $slot, $method);
        my ($h, $code) = ({},);
        Kephra::Base::Package::set_hash($name, $h);
        if ($slot eq 'BEFORE_AND'){
            $code = sub {
                return unless %$h;
                my $ret = {};
                for my $k (keys %$h){ $ret->{$k} = $h->{$k}->(@_) }
                $ret;
             };
        } elsif ($slot eq 'AND_AFTER'){
            $code = sub {
                return unless %$h;
                my $ret = pop;
                for my $k (keys %$h){ $h->{$k}->(@_, $ret->{$k})}
             };
        } else {$code = sub {$_->(@_) for values %$h}}
        Kephra::Base::Package::set_sub($name, $code);
        $ret->{$slot} = $code;
    }
    Kephra::Base::Package::set_hash( Kephra::Base::Class::Scope::construct_path('hook', $class, 'ALL', $method), {});
    $ret;
}

sub has_anchor {
    my ($class, $method, $type) = @_;
    $type = 'BEFORE' unless defined $type;
    Kephra::Base::Package::has_sub( Kephra::Base::Class::Scope::construct_path('hook', $class, $type, $method));
}
################################################################################
sub add {
    my ($class, $method, $slot, $hook, $code, $code2) = @_;
    return 'to add method hook, you need name class, method, slot a hook to create and one or two CODE refs'
        unless ref $code eq 'CODE' and $name{$slot};
    return 'need two CODE blocks for BEFORE_AND_AFTER method hook'
        if $slot eq 'BEFORE_AND_AFTER' and ref $code2 ne 'CODE';
    my $all = Kephra::Base::Package::get_hash(Kephra::Base::Class::Scope::construct_path('hook', $class, 'ALL', $method));
    return "method $class::$method has no anchor, to which a hook can be added" if ref $all ne 'HASH';
    return "can not override a hook" if $all->{$hook};
    $all->{$hook} = $slot;
    if ($slot eq 'BEFORE_AND_AFTER'){
        Kephra::Base::Package::get_hash( Kephra::Base::Class::Scope::name('hook', $class, 'BEFORE_AND', $method))->{$hook} = $code;
        Kephra::Base::Package::get_hash( Kephra::Base::Class::Scope::name('hook', $class, 'AND_AFTER', $method))->{$hook} = $code2;
    } else {
        Kephra::Base::Package::get_hash( Kephra::Base::Class::Scope::name('hook', $class, $slot, $method))->{$hook} = $code;
    }
    0;
}

sub remove {
    my ($class, $method, $hook) = @_;
    return 'to remove method hook, you need to name class, method, and the hook' unless defined $hook;

    my $all = Kephra::Base::Package::get_hash(Kephra::Base::Class::Scope::name('hook', $class, 'ALL', $method));
    return "method $class::$method has no anchor, to which a hook can be added" if ref $all ne 'HASH';
    return "method $class::$method has no hook named $hook" unless $all->{$hook};
    my $slot = delete $all->{$hook};
    if ($slot eq 'BEFORE_AND_AFTER'){
        return (
          delete Kephra::Base::Package::get_hash( Kephra::Base::Class::Scope::name('hook', $class, 'BEFORE_AND', $method))->{$hook},
          delete Kephra::Base::Package::get_hash( Kephra::Base::Class::Scope::name('hook', $class, 'AND_AFTER', $method))->{$hook}
        );
    } else {
        return delete Kephra::Base::Package::get_hash(Kephra::Base::Class::Scope::name('hook', $class, $slot, $method))->{$hook};
    }
}
sub is_known {
    my ($class, $method, $hook) = @_;
    return 'to check a method hooks existance, you need to name class, method and hook'
        unless defined $method and has_anchor($class, $method);
    return 'method has no anchor' unless has_anchor($class, $method);
    Kephra::Base::Package::get_hash(Kephra::Base::Class::Scope::name('hook', $class, 'ALL', $method))->{$hook};
}

sub list {
    my ($class, $method, $slot) = @_;
    return 'to list hooks of method $class::$method, you need to name class and method of the hook and maybe the hook type'
        unless defined $method and has_anchor($class, $method);
    return 'unknown method hook slot' if defined $slot and not $name{$slot};
    $slot = 'ALL' unless defined $slot;
    $slot = 'BEFORE_AND' if $slot eq 'BEFORE_AND_AFTER';
    my @ret = (keys %{Kephra::Base::Package::get_hash(Kephra::Base::Class::Scope::name('hook', $class, $slot, $method))});
}

################################################################################
1;

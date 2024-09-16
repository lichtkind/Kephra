use v5.14;
use warnings;

package Kephra::API::Object::Hook;
use Kephra::API qw/:log :pkg :test/;
use Kephra::API::Call;
use constant {
    HOOK   => ':HOOK',
    BEFORE => 1,
    AFTER  => 2,
};

################################################################################

sub add_before    { _add(@_, BEFORE)} # obj method HID code --> call
sub add_after     { _add(@_, AFTER) } # obj method HID code --> call
sub _add {
    my ($self, $method, $HID, $action, $slot) = @_;
    return error('need four parameter: object, its method, hook ID, perl code') unless defined $slot and @_ < 6;
    return error('first parameter is not an object reference')                 unless is_object($self);
    my $main_ref = $self->can($method);
    return error("second parameter is not a method of given object $self")  unless $main_ref;
    return warning("a hook with ID: $HID for slot $slot is already installed") 
        if defined $self->{HOOK()}{$method}{$slot}{$HID};

    my $sub_name = (ref $self) . '::' . $method;
    my $main_name = $sub_name.':::MAIN';
    no strict   qw/refs/;
    no warnings qw/redefine /; # uninitialized
    unless (defined *{$main_name}{'CODE'}) {
        *{$main_name} = $main_ref;
        *{$sub_name} = sub {
             my ($self, @param) = @_;
             my %before_ret = ();
             if (defined $self->{HOOK()}{$method}){
                 for my $ID (keys %{$self->{HOOK()}{$method}{BEFORE()}}) {
                     my $call = $self->{HOOK()}{$method}{BEFORE()}{$ID};
                     $before_ret{$ID} = [$call->run($self, [@param], [$HID, $ID])] if is_call($call);
                 }
             }
             my @main_ret = $main_ref->($self, @param);
             if (defined $self->{HOOK()}{$method}){
                 for my $ID (keys %{$self->{HOOK()}{$method}{AFTER()}}) {
                     my $call = $self->{HOOK()}{$method}{AFTER()}{$ID};
                     $call->run($self, [@param], [$HID, $ID], $before_ret{$ID}, [@main_ret]) if is_call($call);
                 }
             }
             @main_ret;
        }
    }
    $self->{HOOK()}{$method}{$slot}{$HID} = is_call($action) 
        ? $action 
        : Kephra::API::Call->new($method.':'.$slot.':'.$HID, $action);
}

################################################################################

sub get_before_IDs {_get_IDs(@_, BEFORE)}  # obj method  --> [HID]
sub get_after_IDs  {_get_IDs(@_, AFTER)}   # obj method  --> [HID]
sub _get_IDs {
    my ($self, $method, $slot) = @_;
    return error('need two parameter: an object and its method name')  unless defined $slot and @_ < 4;
    return error('first parameter is not an object reference')           unless is_object($self);
    return error("second parameter is not a method of given object $self") unless $self->can($method);
    return 0 unless defined $self->{HOOK()}{$method} and ref $self->{HOOK()}{$method}{$slot} eq 'HASH';
    keys %{$self->{HOOK()}{$method}{$slot}};
}

sub get_methods  {   # obj                 --> [method]
    my ($self) = @_;
    return error('need one parameter, an object') 
        unless defined $self and @_ < 2 and is_object($self);
    return 0 unless ref $self->{HOOK()} eq 'HASH';
    keys %{$self->{HOOK()}};
}

################################################################################

sub get_before    {_get(@_, BEFORE)}  # obj method HID      --> call
sub get_after     {_get(@_, AFTER)}   # obj method HID      --> call
sub _get {
    my ($self, $method, $HID, $slot) = @_;
    return error('need three parameter: object, its method and a hook ID') unless defined $slot and @_ < 5;
    return error('first parameter is not an object reference')             unless is_object($self);
    return error("second parameter is not a method of given object $self") unless $self->can($method);
    return warning("no hook for method $method is installed")
        unless defined $self->{HOOK()}{$method};
    return warning("no hook for slot $slot is installed")
        unless defined $self->{HOOK()}{$method}{$slot};
    return warning("no hook with ID: $HID for slot $slot is installed")
        unless defined $self->{HOOK()}{$method}{$slot}{$HID};

    $self->{HOOK()}{$method}{$slot}{$HID};
}

################################################################################

sub remove_before { _remove(@_, BEFORE)} # obj method HID      --> call
sub remove_after  { _remove(@_, AFTER) } # obj method HID      --> call
sub _remove       { # obj method HID     --> 0|1
    my ($self, $method, $HID, $slot) = @_;
    return error('need three parameter: object, its method and a hook ID') unless defined $slot and @_ < 5;
    return error('first parameter is not an object reference')             unless is_object($self);
    return error("second parameter is not a method of given object $self") unless $self->can($method);
    return warning("a hook with ID: $HID for slot $slot is not installed")
        unless defined $self->{HOOK()}{$method}{$slot}{$HID};

    my $ret = delete $self->{HOOK()}{$method}{$slot}{$HID};
    delete $self->{HOOK()}{$method} if keys %{$self->{HOOK()}{$method}{BEFORE()}} == 0
                                   and keys %{$self->{HOOK()}{$method}{AFTER()}} == 0;
    $ret;
}

1;

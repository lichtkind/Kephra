use v5.14;
use warnings;

package Method;

sub new {
    my ($package, @params ) = @_;
    my $self = bless {}, $package;
    $self->BUILD( @params );

    no strict   qw/refs/;
    no warnings qw/redefine uninitialized/;
    my $hooks_exists = __PACKAGE__.'::'.$package.':::E';
    if (defined *{$hooks_exists}{'CODE'}) {
        say "already seen package $package";
    } else {
        say "not seen package $package yet";
        say "will install hooks into methods:";
        for my $method ( keys %{$package.'::'}) {
             next if substr($method, 0, 1)  eq '_'
                  or substr($method, -1) eq ':'
                  or        $method    eq 'new'
                  or        $method eq uc $method
                  or not defined *{$package.'::'.$method}{'CODE'};
             my $ref = *{"$package::$method:main"} = *{"$package::$method"}{'CODE'};
             say "    - $method \t $ref ", *{"$package::$method"}{CODE};
             *{$package.'::'.$method} = sub {
                 my ($self, @param) = @_;
                 my @before = ();
                 say "calling method: $method ", $self->{"::$method:before"};
                 @before = $self->{"::$method:before"}->($self, @param)
                     if ref $self->{"::$method:before"} eq 'CODE';
                 my @ret = $ref->($self, @param);
                 $self->{"::$method:after"}->($self, [@param], [@before], [@ret])
                     if ref $self->{"::$method:after"} eq 'CODE';
                 @ret;
             };
             say "made method: $method ",*{"$package::$method"}{'CODE'},*{"$package::$method:main"}{'CODE'};

        }
        *{$hooks_exists} = sub {};
    }
    $self;
}

sub insert_hook_before {
    my ($self, $method, $code) = @_;
    #return error('need uncompiled perl code as first parameter') unless defined $code;
    no strict   qw/refs/;
    no warnings qw/redefine uninitialized/;
    eval '$self->{\'::'.$method.":before'} = sub {$code}";
}

sub remove_hook_before {
    my ($self, $method) = @_;
    delete $self->{"::$method:before"};
}

sub insert_hook_after {
    my ($self, $method, $code) = @_;
    #return error('need uncompiled perl code as first parameter') unless defined $code;
    no strict   qw/refs/;
    no warnings qw/redefine/;
    eval '$self->{\'::'.$method.":after'} = sub {$code}";
}

sub remove_hook_after {
    my ($self, $method) = @_;
    delete $self->{"::$method:after"};
}

sub sub {1}
sub _private {'don\'t look'}

1;

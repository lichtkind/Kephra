package Mo;
$Mo::VERSION = '0.40';
$VERSION='0.40';
no warnings;
my $Mo =__PACKAGE__.'::';

*{$Mo.Object::new} = sub { my $class = shift;
                          my $self = bless {@_}, $class;
                          my %name = %{$class.'::'.':E'};
                          map {print "name $_ "; $self->{$_} = $name{$_}->() if ! exists $self->{$_}} keys %name;
print "new mo class $class \n", keys %name;
                          $self };

*{$Mo.import} = sub { import warnings;
                     $^H |= 1538;
print "mo import: @_\n";
                     my( $Package, %e, %o ) = caller.'::';
print "package is $Package \n";
                     shift;
                     eval"no Mo::$_", &{$Mo.$_.::e}($Package,\%e,\%o,\@_) for @_;
                     return if $e{M};
                     %e = (extends, sub { eval"no $_[0]()";
                                          @{$Package.ISA} = $_[0] },
                           has,     sub { my $name = shift;
print "has $name \n";
                                          my $m = sub { $#_ ? $_[0]{$name} = $_[1] : $_[0]{$name} };
                                          @_ = (default,@_) if !($#_%2);
                                          $m = $o{$_}->($m, $name, @_) for sort keys %o;
                                          *{$Package.$name} = $m }
                           ,%e,);

                     *{$Package.$_} = $e{$_} for keys%e;
                     @{$Package.ISA} = $Mo.Object };


__END__

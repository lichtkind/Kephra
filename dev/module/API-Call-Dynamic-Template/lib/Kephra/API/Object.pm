use v5.14;
use warnings;

package Kephra::API::Object;
use Kephra::API qw/:log is_object/;

my %required_methods_check;
my @required_methods = qw/status/;

sub new { #
    my ($package, @params ) = @_;

    unless ($required_methods_check{$package}){
        no strict 'refs';
        for my $method (@required_methods){
            error("package $package misses method $method") unless has_method($package, $method);
        }
        $required_methods_check{$package}++;
    }

    my $self = bless {}, $package;
    my $ret = $self->BUILD( @params );

    $ret;
}

sub has_method {
    return error('need two parameter: package or object and method name') if @_ != 2;
    my ($package, $method) = @_;
    $package = ref $package if ref $package;
    no strict 'refs';
    defined *{"$package::$method"}{'CODE'};
}

1;

use v5.16;
use warnings;

package Kephra::API::Object;
use Kephra::API qw/:log has_sub blessed/;
use Kephra::API::Data qw/clone_item/;
use Kephra::API::Class;

my %required_methods_checked;
my @required_methods = qw/BUILD status/;

################################################################################

sub new { #
    my ($package, @params ) = @_;

    if (not $required_methods_checked{$package}){
        for my $method (@required_methods){
            return error("package $package misses method $method") unless has_sub($package, $method);
        }
        $required_methods_checked{$package}++;
    }
    
    my $self = bless {}, $package;
    my $ret = $self->BUILD( @params );

    $ret;
}

sub clone { clone_item( $_[0] ) }


1;

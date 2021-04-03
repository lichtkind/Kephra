use v5.14;
use warnings;

package Kephra::API::Object;
use Kephra::API qw/:log has_sub/;

my %required_methods_check;
my @required_methods = qw/BUILD status/;

sub new { #
    my ($package, @params ) = @_;

    if (not defined $required_methods_check{$package}){
        for my $method (@required_methods){
            return error("package $package misses method $method") unless has_sub($package, $method);
        }
        $required_methods_check{$package}++;
    }

    my $self = bless { created => {}}, $package;
    bless $self->{created}, 'Kephra::API::Object::Created';
#    ($self->{created}->{'date'}, $self->{created}->{'time'}) = (date_time());
#    $self->{sender} = (sub_caller());

    my $ret = $self->BUILD( @params );

    $ret;
}

#sub created { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{created}; }


package Kephra::API::Object::Created;
use Kephra::API qw/:log/;

sub package   { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{package}; }
sub sub       { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{sub};    }
sub file      { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{file};  }
sub line      { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{line}; }
sub time      { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{time}; }
sub date      { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{date}; }

1;

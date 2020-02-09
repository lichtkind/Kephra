use v5.14;
use warnings;

package Kephra::API::Object;
use Kephra::API qw/:log has_sub blessed/;

my %required_methods_check;
my @required_methods = qw/BUILD status/;
my %copied_reftype = ('' => 1, Regexp => 1, CODE => 1, FORMAT => 1, IO => 1, GLOB => 1, LVALUE => 1);

sub new { #
    my ($package, @params ) = @_;

    if (not defined $required_methods_check{$package}){
        for my $method (@required_methods){
            return error("package $package misses method $method") unless has_sub($package, $method);
        }
        $required_methods_check{$package}++;
    }
    
    my $self = bless {}, $package;
    my $ret = $self->BUILD( @params );

    $ret;
}

sub clone { _clone_recursive( $_[0] ) }
sub _clone_recursive {
    my ($data) = @_;
    return unless defined $data;

    my ($class, $ref, $ret) = (blessed($data));
    if ($class) {
        $ref = "$data";
        $ref = substr $ref, 1 + length($class), index($ref, '(' ) - length($class) - 1;
    } else { 
        $ref = ref $data 
    }
    return $data if $copied_reftype{$ref};

    if    ($ref eq 'HASH')   { $ret->{$_} = _clone_recursive($data->{$_}) for keys %$data }
    elsif ($ref eq 'ARRAY')  { push @$ret, _clone_recursive($_) for @$data  }
    elsif ($ref eq 'REF')    { $ret = \_clone_recursive($$data) }
    elsif ($ref eq 'SCALAR'
        or $ref eq 'VSTRING'){ my $val = $$data; $ret = \$val }
    else                     { } # ?

    $class ? bless($ret, $class) : $ret;
}


package Kephra::API::Object::Created;
use Kephra::API qw/:log/;

sub package   { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{package}; }
sub sub       { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{sub};    }
sub file      { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{file};  }
sub line      { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{line}; }
sub time      { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{time}; }
sub date      { return error('need to be called as method with no parameter') if @_ != 1;  $_[0]->{date}; }

1;

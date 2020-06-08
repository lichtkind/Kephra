use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Method::Signature;
our $VERSION = 0.1;
use Kephra::Base::Data::Type;
my %arg_kind = (arg => 4, attr => 4, foreward => 3, pass => 3, slurp => 3, type => 4);
################################################################################
sub new  { # %def     --> _
    my ($pkg, $sig_def) = (@_);
    return "need an array reference with at least three values (argument count of required, optional and return part)" unless ref $sig_def eq 'ARRAY' and @$sig_def > 2;
    return "argument count of required, optional and return part do not match signature length" unless @$sig_def == $sig_def->[0] + $sig_def->[1] + $sig_def->[2] + 3;
    for my $i (3..$#$sig_def){
        my $arg = $sig_def->[$i];
        next unless ref $arg;
        return "$i'th argument is not defined by as array or string" if ref $arg ne 'ARRAY';
        $sig_def->[$i] = $arg->[0] if @$arg == 1;
        next if @$arg < 3;
        my $k = $arg->[2];
        return "$i'th argument is of unknown type kind $k" unless defined $arg_kind{$k};
        return "$i'th argument is kind $k and should be defined by $arg_kind{$k} values" unless $arg_kind{$k} == @$arg;
    }
    bless $sig_def;
}
sub check_types { # {~attr => ~type}, >@.store --> ~errormsg
    my ($self, $attr, @store) = (@_);

}
################################################################################
sub state       { # $_       --> %state
    
}

sub restate     { # %state   --> _
    
}
################################################################################

1;

__END__

 [~]                   1    # ~ means argument name
 [~ T]                 2    # T means argument main type
 [~ T? 'foreward']     3    # constructor arg thats forewards to attribute
 [~ T? 'slurp']        3    # a.k.a. >@ ; T? means most of time its empty = ''
 [~ T? 'pass']         3    # a.k.a. -->' '
 [~ T  'type'   T]     4 
 [~ T  'arg'    ~  T!] 5    # T! means Type of argument (parameter type of main type) will be added later by Definition::Method::Signature
 [~ T  'attr'   ~  T!] 5    # T! means Type of attribute (parameter type of main type) will be added later by Definition::Method::Signature

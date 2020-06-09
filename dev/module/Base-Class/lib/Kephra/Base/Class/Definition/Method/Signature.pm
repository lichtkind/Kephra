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
        return "$i'th argument is not defined by as array" if ref $arg ne 'ARRAY';
        next if @$arg < 3;
        return "$i'th argument is of unknown type kind $arg->[2]" unless defined $arg_kind{$arg->[2]};
        return "$i'th argument is kind $arg->[2] and should be defined by $arg_kind{$arg->[2]} values" unless $arg_kind{$arg->[2]} == @$arg;
    }
    bless $sig_def;
}
sub check_types { # {~attr => ~type}, >@.store --> ~errormsg
    my ($self, $attr, @store) = (@_);
    for my $i (3..$#$self){
        next if @{$self->[$i]} == 1;
        $arg->{$self->[$_][0]} = $self->[$_][1] if @{$self->[$_]} == 2;
    }

    for (3..$#$self){
        $arg->{$self->[$_][0]} = $self->[$_][1] if @{$self->[$_]} == 2;
    }
    my $arg = {};
    for my $i (3..$#$self){
        if (@{$self->[$i]} == 4){
            
        }
    }
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
 [~ T  'type'   T]     4 
 [~ T  'arg'    ~  T!] 5    # T! means Type of argument (parameter type of main type) will be added later by Definition::Method::Signature
 [~ T  'attr'   ~  T!] 5    # T! means Type of attribute (parameter type of main type) will be added later by Definition::Method::Signature

# [~ T? 'pass']         3    # a.k.a. -->' '

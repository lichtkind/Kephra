use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Method::Signature;
our $VERSION = 0.1;
use Kephra::Base::Data::Type;
my %arg_kind = (arg => 4, attr => 4, foreward => 3, slurp => 3, type => 4);
################################################################################
sub new  { # %def     --> _
    my ($pkg, $sig_def) = (@_);
    $name = {};
    return "need a hash reference to create signature object ".__PACKAGE__ unless ref $sig_def eq 'HASH';
    for my $k (qw/req opt ret/){
        return "signature definition has no hash key $k" unless exists $sig_def->{$k};
        next unless ref $sig_def->{$k};
        return "signature definition part $k has to have string or array content" if ref $sig_def->{$k} ne 'ARRAY'
        for my $i (0 .. $#{$sig_def->{$k}}){
            my $arg = $sig_def->{$k}[$i];
            my $elem_help = "$i'th element of signature definition part $k";
            unless (ref $arg){
                return "$elem_help is empty" unless defined $arg and $arg;
                return "$elem_help has the already take name $arg" if $name{$arg};
                $name{$arg}++;
                next;
            }
            #;
             unless ref $arg;
             return "$elem_help has to have string or array content" if ref $arg ne 'ARRAY';
             if (@$arg == 1){ $sig_def->{$k}[$i] = $arg->[0];
             } elsif (@$arg == 2){
             } else {
             }
             $sig_def->{$k}
        }

        
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
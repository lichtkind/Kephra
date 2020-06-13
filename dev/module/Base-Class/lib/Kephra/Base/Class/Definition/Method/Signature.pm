use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Method::Signature;
our $VERSION = 0.1;
use Kephra::Base::Data::Type;
my %arg_kind = (arg => 4, attr => 4, foreward => 3, slurp => 3, type => 4);
################################################################################
sub new  { # %def     --> _
    my ($pkg, $sig_def) = (@_);
    return "need a hash reference to create signature object ".__PACKAGE__ unless ref $sig_def eq 'HASH';
    for my $k (qw/required optional return/){
        return "signature definition has no hash key $k" unless exists $sig_def->{$k};
        next unless ref $sig_def->{$k};
        return "signature definition part $k has to have string or array content" if ref $sig_def->{$k} ne 'ARRAY';
        for my $i (0 .. $#{$sig_def->{$k}}){
            my ($arg, $elem_help) = ($sig_def->{$k}[$i], "$i'th element of signature definition part $k");
            $arg = [$arg] unless ref $arg;
            return "$elem_help has to have string or array content" if ref $arg ne 'ARRAY';
            return "$elem_help has no valid name (a-z,a-z0-9_)" if Kephra::Base::Data::Type::standard->check_basic_type('identifier', $arg->[0]);
            return "$elem_help has the already take name $arg->[0]" if exists $sig_def->{'name'}{$arg->[0]};
            $sig_def->{'name'}{$arg->[0]}++;
            if (@$arg == 1){ $sig_def->{$k}[$i] = $arg->[0] }  
            elsif (@$arg == 2){
                $sig_def->{'name'}{$arg->[0]} = $arg->[1];
                push @{$sig_def->{'type'}{'basic'}}, $arg;
                push @{$sig_def->{'shortcut'}{'basic'}}, $arg if length $arg->[1] == 1;
            } else {
                return "$elem_help is of unknown type kind $arg->[2]" unless defined $arg_kind{$arg->[2]};
                return "$elem_help is a $arg->[2] and should be defined by ".$arg_kind{ $arg->[2] }.' values' unless $arg_kind{$arg->[2]} == @$arg;
                push @{$sig_def->{'category'}{$arg->[2]}}, $arg;
                if ($arg->[2] eq 'slurp'){
                    return "the slurpy argument $arg->[0] has to be the last argument" if $i != $#{$sig_def->{$k}} or ($k eq 'required' and ref $sig_def->{'optional'} eq 'ARRAY');
                } elsif (@$arg > 3){
                    push @{$sig_def->{'type'}{'param'}}, $arg;
                    push @{$sig_def->{'shortcut'}{'param'}}, $arg if length $arg->[1] == 1;
                }
            }
        }
    }
    bless $sig_def;
}

sub adapt_to_class { # ~class {~attr => ~type}, >@.store --> ~errormsg
    my ($self, $class, $attr, @store) = (@_);
# resolve type shortcuts
# insert parameter type
# insert foreward type
# insert self type
# check types existance
#    for my $i (3..$#$self){
#        next if @{$self->[$i]} == 1;
#        $arg->{$self->[$_][0]} = $self->[$_][1] if @{$self->[$_]} == 2;
#    }
#
#    for (3..$#$self){
#        $arg->{$self->[$_][0]} = $self->[$_][1] if @{$self->[$_]} == 2;
#    }
    if (ref $self->{'category'}{'arg'} eq 'ARRAY'){
        for my $arg (@{$self->{'category'}{'arg'}}){
            return "argument $arg->[0] does reference an unknown argument" unless exists $self->{'name'}{$arg->[3]};
            return "argument $arg->[0] does reference an argument with parametric or special type (only basic typed allowed)" if $self->{'name'}{$arg->[3]} eq 1;
            push @$arg, $self->{'name'}{$arg->[3]};
        }
    }
#    my $arg = {};
#    for my $i (3..$#$self){
#        if (@{$self->[$i]} == 4){
#            
#        }
#    }
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
 [~ T? 'self']         3    # a.k.a. _  ; typed_ref class
 [~ T  'type'   T]     4 
 [~ T  'arg'    ~  T!] 5    # T! means Type of argument (parameter type of main type) will be added later by Definition::Method::Signature
 [~ T  'attr'   ~  T!] 5    # T! means Type of attribute (parameter type of main type) will be added later by Definition::Method::Signature

# [~ T? 'pass']         3    # a.k.a. -->' ', now return => []
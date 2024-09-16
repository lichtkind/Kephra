use v5.20;
use warnings;

# signature defintition object - req, opt  x in, out
package Kephra::Base::Class::Definition::Method::Signature;

our $VERSION = 0.0;
use Kephra::Base::Data::Type qw/is_type_known resolve_type_shortcut/;
my %arg_kind = (Arg => 4, Attr => 4, Foreward => 3, Slurp => 3, Type => 4);
my $is_ID = Kephra::Base::Data::Type::standard->get_type('identifier')->get_checker();
################################################################################
sub new  { # %def     --> _
    my ($pkg, $sig_def) = (@_);
    return "need a hash reference to create signature object ".__PACKAGE__ unless ref $sig_def eq 'HASH';
    return "hash ref can only contain 3 keys: required optional return" if keys %$sig_def != 3;
    $sig_def->{'type'}     = {basic => [], param => []};
    $sig_def->{'category'}{$_} = [] for keys %arg_kind;
    for my $k (qw/required optional return/){
        return "signature definition has no hash key $k" unless exists $sig_def->{$k};
        next unless ref $sig_def->{$k};
        return "signature definition part $k has to have string or array content" if ref $sig_def->{$k} ne 'ARRAY';
        for my $i (0 .. $#{$sig_def->{$k}}){
            my ($arg, $elem_help) = ($sig_def->{$k}[$i], "$i'th element of signature definition part $k");
            $arg = [$arg] unless ref $arg;
            return "$elem_help has to have string or array content" if ref $arg ne 'ARRAY';
            return "$elem_help has no valid name (a-z,a-z0-9_)" if $is_ID->( $arg->[0] );
            return "$elem_help has the already take name $arg->[0]" if exists $sig_def->{'name'}{$arg->[0]};
            $sig_def->{'name'}{$arg->[0]}++;
            if (@$arg == 1){ $sig_def->{$k}[$i] = $arg->[0] }  
            elsif (@$arg == 2){
                $sig_def->{'name'}{$arg->[0]} = $arg->[1];
                push @{$sig_def->{'type'}{'basic'}}, $arg;
            } else {
                return "$elem_help is of unknown type kind $arg->[2]" unless defined $arg_kind{$arg->[2]};
                return "$elem_help is a $arg->[2] and should be defined by ".$arg_kind{ $arg->[2] }.' values' unless $arg_kind{$arg->[2]} == @$arg;
                push @{$sig_def->{'category'}{$arg->[2]}}, $arg;
                if ($arg->[2] eq 'Slurp'){
                    return "the slurpy argument $arg->[0] has to be the last argument" if $i != $#{$sig_def->{$k}} or ($k eq 'required' and ref $sig_def->{'optional'} eq 'ARRAY');
                } elsif (@$arg > 3){
                    next if $arg->[2] eq 'Type';
                    push @{$sig_def->{'type'}{'param'}}, $arg;
                }
            }
        }
    }
    bless $sig_def;
}

sub check_argument{
    my ($def) = (@_);
}

sub check_return_type{
    my ($def) = (@_);
}

sub adapt_to_class { # ~class {~attr => ~type}, >@.store --> ~errormsg
    my ($self, $class, $attr, @store) = (@_);
    return "this signature was already adapted to a class" unless exists $self->{'type'};
    return "need a hash as second argument to adapt signature to a class" if ref $attr ne 'HASH';
    for (@store){ return "value $_ is not a type store to adapt a signature to a class" if ref $_ ne 'Kephra::Base::Data::Type::Store' }
    for my $arg (@{$self->{'type'}{'basic'}}){
        ($arg->[1] = resolve_type_shortcut('basic', $arg->[1], '', @store)) 
            or return "could not resolve basic type shortcut $arg->[1] of argument $arg->[0]" if length $arg->[1] == 1;
        return "argument $arg->[0] has the unknown basic type $arg->[1]" unless is_type_known($arg->[1], '', @store);
    }
    for my $arg (@{$self->{'type'}{'param'}}, @{$self->{'category'}{'Type'}}){ # resolve shortcuts
        ($arg->[1] = resolve_type_shortcut('param', $arg->[1], '', @store))
            or return "could not resolve parametric type shortcut $arg->[1] of argument $arg->[0]" if length $arg->[1] == 1;
    }
    for my $arg (@{$self->{'category'}{'Type'}}){
        ($arg->[3] = resolve_type_shortcut('basic', $arg->[3], '', @store)) or return "could not resolve (basic) parameter type shortcut $arg->[3] of argument $arg->[0]";
        is_type_known([$arg->[1],'element_type'], '', @store) or return "argument $arg->[0] refers to the unknown meta type $arg->[1]";
    }
    for my $arg (@{$self->{'type'}{'basic'}}){
    }
    delete $self->{'category'};
    delete $self->{'shortcut'};
    delete $self->{'type'};
# replace basic shortcuts
# replace param shortcuts
# insert self type
# insert attr type
# insert foreward type
# insert parameter type
# insert arg type
# check basic types existance
# check param types existance
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

 name
[name type]
[name [type para]]
[name [type      attr]]
[name type              default]
[name type                      slurpy]
[name type                              foreward]


  index    bedeutung
 
    0  ~    arg name
    1  *    slurpy property
    2  =    foreward (pass) property
    3  Tb   type name
    4  Tp   parameter type name  
    5  ~:   attr parameter   
    6  ~|   arg parameter   

    0  *    slurpy property
    1  Tb   type name
    2  Tp   parameter type name  
    3  ~:   attr parameter   
    4  ~|   arg parameter   

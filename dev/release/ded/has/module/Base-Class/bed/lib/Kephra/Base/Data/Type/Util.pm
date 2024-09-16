use v5.20;
use warnings;

# helper functions for type creation

package Kephra::Base::Data::Type::Util;
our $VERSION = 1.01;
use Kephra::Base::Data::Type::Store;

our @type_class_names = qw/Kephra::Base::Data::Type::Basic
                           Kephra::Base::Data::Type::Parametric/;
################################################################################
sub can_substitude_names {   # %type_def              --> =amount
    my $type_def = shift;
    return 0 unless ref $type_def eq 'HASH';
    (defined $type_def->{'parent'} and not ref $type_def->{'parent'})         +
    (defined $type_def->{'parent'} and ref $type_def->{'parent'} eq 'ARRAY')  +
    (exists $type_def->{'parameter'} and not ref $type_def->{'parameter'})    +
    (ref $type_def->{'parameter'} eq 'HASH' and exists $type_def->{'parameter'}{'parent'} and not ref $type_def->{'parameter'}{'parent'});
}
sub substitude_names {   # %type_def @.type_store      --> =amount
    my $type_def = shift;
    return 0 unless ref $type_def eq 'HASH';
    my $amount = 0;
    for my $store (@_){
        next unless ref $store eq 'Kephra::Base::Data::Type::Store';
        if (defined $type_def->{'parent'} and not ref $type_def->{'parent'}){
            my $tmp = $store->get_type( $type_def->{'parent'} );              $type_def->{'parent'} = $tmp, $amount++ if ref $tmp;
        } elsif (ref $type_def->{'parent'} eq 'ARRAY'){
            my $tmp = $store->get_type( @{$type_def->{'parent'}} );           $type_def->{'parent'} = $tmp, $amount++ if ref $tmp;
        }
        if (ref $type_def->{'parameter'} eq 'HASH' and exists $type_def->{'parameter'}{'parent'} and not ref $type_def->{'parameter'}{'parent'}){
            my $tmp = $store->get_type($type_def->{'parameter'}{'parent'});   $type_def->{'parameter'}{'parent'} = $tmp, $amount++ if ref $tmp;
        } elsif (exists $type_def->{'parameter'} and not ref $type_def->{'parameter'}){
            my $tmp = $store->get_type( $type_def->{'parameter'} );           $type_def->{'parameter'} = $tmp, $amount++ if ref $tmp;
        }
    }
    $amount;
}
sub create_type {        # %type_def @.type_store      --> .type
    my $type_def = shift;
    return "need a type definition (hash ref) as argument" unless ref $type_def eq 'HASH';
    for my $store (@_){
        substitude_names($type_def, $store) if ref $store eq 'Kephra::Base::Data::Type::Store';
    }
    (exists $type_def->{'parameter'} or ref $type_def->{'parent'} eq 'Kephra::Base::Data::Type::Parametric')
        ? Kephra::Base::Data::Type::Parametric->new($type_def)
        : Kephra::Base::Data::Type::Basic->new($type_def);
}
sub is_type {
    my $ref = shift;
    for (@type_class_names){ return 1 if ref $ref eq $_ } 0;
}

################################################################################

5;

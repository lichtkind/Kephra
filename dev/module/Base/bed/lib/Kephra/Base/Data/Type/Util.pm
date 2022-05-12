use v5.20;
use warnings;

# helper functions for type creation

package Kephra::Base::Data::Type::Util;
our $VERSION = 1.01;
use Kephra::Base::Data::Type::Store;

our @type_class_names = qw/Kephra::Base::Data::Type::Basic
                           Kephra::Base::Data::Type::Parametric/;
################################################################################
# replace_name_with_type

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

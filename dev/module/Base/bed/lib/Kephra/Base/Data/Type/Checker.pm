use v5.20;
use warnings;
use feature "switch";
no warnings 'experimental::smartmatch';

# holds one or several type stores, apply type checking

package Kephra::Base::Data::Type::Checker;
our $VERSION = 0.01;

use Kephra::Base::Data::Type::Store;


sub check_basic_type {                     # .tstore ~type $val              -->  ~errormsg
    my ($self, $type_name, $value) = @_;
    my $type = $self->get_type( $type_name );
    return "no basic type named $type_name is known by this store" unless ref $type;
    $type->check($value);
}
sub check_param_type {                     # .tstore ~type ~param $val $pval -->  ~errormsg
    my ($self, $type_name, $param_name, $value, $param_value) = @_;
    my $type = $self->get_type( $type_name, $param_name );
    return "no type $type_name with parameter $param_name is known by this store" unless ref $type;
    $type->check($value, $param_value);
}
sub guess_basic_type {                     # .tstore $val                    --> @~type
    my ($self, $value) = @_;
    my @types = $self->list_type_names('basic');
    return undef unless @types;
    map {$_->[0]} sort {$b->[1] <=> $a->[1]} map {[$_->[0], int @{$_->[1]->get_check_pairs}]}
        grep {not $_->[1]->check($value)} map {[$_, $self->get_type($_)]} @types;
}

################################################################################


1;

__END__


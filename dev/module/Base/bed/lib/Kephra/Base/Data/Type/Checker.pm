use v5.20;
use warnings;
use feature "switch";
no warnings 'experimental::smartmatch';

# holds one or several type stores, apply type checking

package Kephra::Base::Data::Type::Checker;
our $VERSION = 0.01;

use Kephra::Base::Data::Type::Namespace;;

sub new {
    my ($pkg, @name_spaces) = @_;

    bless {space_order => [], spaces => {}, open => $_[1]//1, };
}

sub state {

}

sub restate {

}

################################################################################
sub close {
    my ($self) = @_;
}
################################################################################

sub add_namespace{
    my ($self, $ns_name, $name_space, $pos) = @_;

}

sub move_namespace {
    my ($self, $ns_name) = @_;

}

sub remove_namespace {
    my ($self, $ns_name) = @_;

}

sub get_namespace {
    my ($self, $ns_name) = @_;

}


################################################################################

sub get_type {                                 # ~type -- ~param       --> .btype|.ptype|undef
    my ($self, $type_name, $param_name) = @_;
    ($type_name, $param_name) = @$type_name if ref $type_name eq 'ARRAY';
    if (defined $param_name and $param_name){
       return $self->{'param_type'}{$type_name}{$param_name} if exists $self->{'param_type'}{$type_name}
    } else { return $self->{'basic_type'}{$type_name}  }
    undef;
}

sub list_type_names   {                        # - ~kind ~ptype              --> @~btype|@~ptype|@~param
    my ($self, $kind, $type_name) = @_;        # kind = 'basic' | 'param'
    ($kind = _key_from_kind_($kind)) or return;
    if (defined $type_name){
        return unless exists $self->{'param_type'}{$type_name} and $kind eq 'param';
        return sort keys %{ $self->{'param_type'}{$type_name}{'object'} };
    }
    sort keys %{$self->{$kind.'_type'}};
}
sub list_shortcuts    {                        #                             --> @~shortcut
    my ($self, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    sort keys( %{$self->{$kind.'_name_by_shortcut'}});
}

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
    map {$_->[0]} sort {$b->[1] <=> $a->[1]} map {[$_->[0], int @{$_->[1]->source}]}
        grep {not $_->[1]->check_data($value)} map {[$_, $self->get_type($_)]} @types;
}

################################################################################


4;

__END__

@stores


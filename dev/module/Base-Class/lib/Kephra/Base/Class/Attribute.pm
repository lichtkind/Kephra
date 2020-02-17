use v5.16;
use warnings;

# central kv storage for all data stored in attributes

package Kephra::Base::Class::Attribute;
our $VERSION = 0.1;
use Kephra::Base::Package qw/set_sub has_sub/;
use Kephra::Base::Class::Scope qw/cat_scope_path/;
use Kephra::Base::Class::Attribute::Type;

my (%store, %setter, %resetter, %tr_getter, %tr_setter);
my $universal_getter = sub{$store{int $_[0]} if ref $_[0] and exists $store{int $_[0]} };

################################################################################
sub create {
    my ($class, $attribute, $attr_types, $type) = @_;
    return 0 unless ref $attr_types eq 'Kephra::Base::Class::Attribute::Type' and defined $type;
    my $callback = $attr_types->get_callback($type);
    my $default = $attr_types->get_default_value($type);
    return 0 unless ref $callback eq 'CODE';

    my $scope = cat_scope_path( 'attribute', $class, $attribute);
    my $k = '';
    my $self = bless \$k, $scope;
    $store{int $self} = $default if defined $default;

    $setter{$class}{$type} = sub { 
        return 0 unless ref $_[0] and exists $store{int $_[0]} and defined $_[1];
        my $a = shift;
        $k = $callback->(@_);
        return 0 if $k;
        $store{int $a} = $_[0];
    } unless ref $setter{$class}{$type};

    $resetter{$class}{$type} = sub { 
        return 0 unless ref $_[0] and exists $store{int $_[0]};
        $store{int $_[0]} = $default;
        $default;
    } unless ref $resetter{$class}{$type};

    set_sub( $scope.'::get', $universal_getter);
    set_sub( $scope.'::set', $setter{$class}{$type});
    set_sub( $scope.'::reset', $resetter{$class}{$type});
    $self;
}

sub add_getter {
    my ($attribute, $attr_ref, $path, $self) = @_;
    return 0 unless ref $attr_ref and exists $store{int $attr_ref} and ref $self;
    $tr_getter{int $self}{$attribute} = $attr_ref;
    set_sub( $path, sub {
        return unless ref $_[0] and ref $tr_getter{int $_[0]};
        $store{int $tr_getter{int $_[0]}{$attribute}};
    });
} 

sub add_setter {
    my ($attribute, $attr_ref, $path, $self) = @_;
    return 0 unless ref $attr_ref and exists $store{int $attr_ref} and ref $self;
    $tr_getter{int $self}{$attribute} = $attr_ref;
    set_sub( $path, sub {
        return unless ref $_[0] and ref $tr_setter{int $_[0]} and defined $_[1];
        my $self = shift;
        my $attr = $tr_getter{int $self}{$attribute};
        my $ret = $attr->set($_[0], $self);
        $$self = $$attr; # copy error msg
        $ret;
    });
} 

sub delete   { 
    my $attr = shift;
    delete $tr_getter{int $_} for @_;
    delete $tr_setter{int $_} for @_;
    delete $store{int $attr} if is_known($attr);
}
################################################################################
sub is_known { (ref $_[0] and exists $store{int $_[0]}) ? 1 : 0 }
sub get      { $store{int $_[0]}         if is_known($_[0]) }
sub set      { $store{int $_[0]} = $_[1] if is_known($_[0]) }
################################################################################

1;

use v5.20;
use warnings;

# attribute constructor

package Kephra::Base::Class::Builder::Attribute;
our $VERSION = 0.1;
use Kephra::Base::Package qw/set_sub has_sub/;
use Kephra::Base::Class::Scope qw/cat_scope_path/;
use Kephra::Base::Class::Attribute::Type;

my (%data, %attr_name, %setter, %resetter, %attr_ref_getter, %attr_ref_setter, %attr_ref_getsetter, %self_ref);
my $universal_getter = sub{$data{int $_[0]} if ref $_[0] and exists $data{int $_[0]} };

################################################################################
sub create {
    my ($class, $attribute, $attr_types, $type) = @_;
    return 0 unless ref $attr_types eq 'Kephra::Base::Class::Attribute::Type' and defined $type;
    my $callback = $attr_types->get_callback($type);
    my $default_value = $attr_types->get_default_value($type);
    return 0 unless ref $callback eq 'CODE';

    my $scope = cat_scope_path( 'attribute', $class, $attribute);
    my $k = '';
    my $attr_ref = bless \$k, $scope;
    $data{int $attr_ref} = $default_value if defined $default_value;
    $attr_name{int $attr_ref} = $attribute;

    $setter{$class}{$type} = sub { 
        return unless ref $_[0] and exists $data{int $_[0]} and defined $_[1];
        my $a = shift;
        $k = $callback->(@_);
        return if $k;
        $data{int $a} = $_[0];
    } unless ref $setter{$class}{$type};

    $resetter{$class}{$type} = sub { 
        return unless ref $_[0] and exists $data{int $_[0]};
        $data{int $_[0]} = $default_value;
    } unless ref $resetter{$class}{$type};

    set_sub( $scope.'::get', $universal_getter);
    set_sub( $scope.'::set', $setter{$class}{$type});
    set_sub( $scope.'::reset', $resetter{$class}{$type});
    $attr_ref;
}

sub add_getter {
    my ($attr_ref, $path, $self) = @_;
    return 0 unless ref $attr_ref and exists $data{int $attr_ref} and ref $self;
    my $attribute = $attr_name{int $attr_ref};
    $attr_ref_getter{int $self}{$attribute} = $attr_ref;
    $self_ref{int $attr_ref}{int $self}++;
    set_sub( $path, sub {
        return unless ref $_[0] and ref $attr_ref_getter{int $_[0]}{$attribute};
        $data{int $attr_ref_getter{int $_[0]}{$attribute}};
    });
    1;
} 
sub add_setter {
    my ($attr_ref, $path, $self) = @_;
    return 0 unless ref $attr_ref and exists $data{int $attr_ref} and ref $self;
    my $attribute = $attr_name{int $attr_ref};
    $attr_ref_setter{int $self}{$attribute} = $attr_ref;
    $self_ref{int $attr_ref}{int $self}++;
    set_sub( $path, sub {
        return unless ref $_[0] and ref $attr_ref_setter{int $_[0]}{$attribute} and defined $_[1];
        my $self = shift;
        my $attr_ref = $attr_ref_setter{int $self}{$attribute};
        my $ret = $attr_ref->set($_[0], $self); # get return value
        $$self = $$attr_ref;    # copy error msg
        $ret;
    });
    1;
}
sub add_getsetter {
    my ($attr_ref, $path, $self) = @_;
    return 0 unless ref $attr_ref and exists $data{int $attr_ref} and ref $self;
    my $attribute = $attr_name{int $attr_ref};
    $attr_ref_getsetter{int $self}{$attribute} = $attr_ref;
    $self_ref{int $attr_ref}{int $self}++;
    set_sub( $path, sub {
        return unless ref $_[0] and ref $attr_ref_getsetter{int $_[0]}{$attribute};
        my $self = shift;
        my $attr_ref = $attr_ref_getsetter{int $self}{$attribute};
        return $data{int $attr_ref} unless defined $_[0];
        my $ret = $attr_ref->set($_[0], $self);
        $$self = $$attr_ref; # copy error msg
        $ret;
    });
    1;
}

sub delete   { # autodelete translations?
    my $attr_ref = shift;
    return 0 unless ref $attr_ref and exists $data{int $attr_ref};
    my $attribute = delete $attr_name{int $attr_ref};
    my $self = delete $self_ref{int $attr_ref};
    delete $attr_ref_getter{$_}{$attribute} for keys %$self;
    delete $attr_ref_setter{$_}{$attribute}  for keys %$self;
    delete $attr_ref_getsetter{$_}{$attribute} for keys %$self;
    delete $data{int $attr_ref};
}

sub remove_class {}
################################################################################
sub is_known { (ref $_[0] and exists $data{int $_[0]}) ? 1 : 0 }
sub get      { $data{int $_[0]}         if is_known($_[0]) }
sub set      { $data{int $_[0]} = $_[1] if is_known($_[0]) }
################################################################################

1;

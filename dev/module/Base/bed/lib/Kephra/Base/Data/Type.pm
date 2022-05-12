use v5.20;
use warnings;

# organize type related symbols, mostly easy access to stdandard types

package Kephra::Base::Data::Type;
our $VERSION = 1.52;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::NameSpace;
use Kephra::Base::Data::Type::Checker;
use Kephra::Base::Data::Type::Standard;
use Exporter 'import';
our @EXPORT_OK = qw/create_type check_type guess_type is_type_known resolve_type_shortcut/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

################################################################################
my $standard_types = Kephra::Base::Data::Type::Standard::init_store();
my $shared_types = Kephra::Base::Data::Type::Store->new('open'); 
my $STORE = 'Kephra::Base::Data::Type::Store';
sub standard    { $standard_types }
sub shared      { $shared_types }
sub class_names { @Kephra::Base::Data::Type::Util::type_class_names }
################################################################################
sub state       { $shared_types->state }
sub restate     { $shared_types = Kephra::Base::Data::Type::Store->restate($_[0]) }
################################################################################
sub is_known      { &is_type_known }
sub is_type_known { # ~type|[~type ~param] ?shared @.type_store  --> ?
    my ($type_name, $shared, @store, $param_name) = @_;
    ($type_name, $param_name) = @$type_name if ref $type_name eq 'ARRAY';
    push @store, $shared_types if $shared;
    for ($standard_types, @store){
        next if ref $_ ne $STORE;
        return 1 if $_->is_type_known($type_name, $param_name);
    }
    0;
}
sub resolve_shortcut { &resolve_type_shortcut }
sub resolve_type_shortcut { # ~kind ~shortcut @.type_store                   --> ~type|undef
    my ($kind, $shortcut, $shared, @store) = (@_);
    push @store, $shared_types if $shared;
    for ($standard_types, @store){
        next if ref $_ ne $STORE;
        my $type = $_->resolve_shortcut($kind, $shortcut);
        return $type if defined $type;
    }
}

sub create      { &create_type }
sub create_type {
    my ($type_def, $shared, @store) = @_;
    push @store, $shared_types if $shared;
    Kephra::Base::Data::Type::Util::create_type($_[0], $standard_types, @store);
}

sub check      { &check_type }
sub check_type {
    my ($type_name, $value, $shared, @store) = @_;
    push @store, $shared_types if $shared;
    for ($standard_types, @store){
        next if ref $_ ne $STORE;
        return $_->check_basic_type($type_name, $value) if $_->is_type_known($type_name);
    } 
    "KBOS type '$type_name' is not known";
}

sub guess      { &guess_type }
sub guess_type {
    my ($value, $shared, @store) = @_;
    push @store, $shared_types if $shared;
    my @ret;
    for ($standard_types, @store){
        next if ref $_ ne $STORE;
        push @ret, $_->guess_basic_type($value);
    }
    grep {defined $_} @ret;
}
################################################################################

7;

__END__


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
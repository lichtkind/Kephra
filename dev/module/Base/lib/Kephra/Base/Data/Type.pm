use v5.20;
use warnings;

# organize type related symbols

package Kephra::Base::Data::Type;
our $VERSION = 0.5;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;
use Kephra::Base::Data::Type::Standard;
use Exporter 'import';
our @EXPORT_OK = qw/create_type check_type guess_type is_type_known/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

################################################################################

Kephra::Base::Data::Type::Standard::init_store();
my $standard_types = Kephra::Base::Data::Type::Standard::get_store();
my $shared_types = Kephra::Base::Data::Type::Store->new(''); 
sub standard    { $standard_types }
sub shared      { $shared_types }
sub class_names { @Kephra::Base::Data::Type::Standard::type_class_names }

################################################################################
sub create      { &create_type }
sub create_type {
    my ($type_def, $type) = @_;
    return "need a type definition (hash ref) as argument" unless ref $type_def eq 'HASH';
    $standard_types->substitude_type_names( $type_def );
    (exists $type_def->{'parameter'} or ref $type_def->{'parent'} eq 'Kephra::Base::Data::Type::Parametric')
        ? Kephra::Base::Data::Type::Parametric->new($type_def)
        : Kephra::Base::Data::Type::Basic->new($type_def);
}

sub check      { &check_type }
sub check_type {
    my ($type_name, $value, $all) = @_;
    $standard_types->check_basic_type($type_name, $value);
}

sub guess      { &guess_type }
sub guess_type {
    my ($value, $all) = @_;
    $standard_types->guess_basic_type($value);
}

sub is_known      { &is_type_known }
sub is_type_known {
    my ($type_name, $param_name, $all) = @_;
    $standard_types->is_type_known($type_name, $param_name);
}
################################################################################

6;

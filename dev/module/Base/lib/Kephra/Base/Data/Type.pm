use v5.20;
use warnings;

# organize type related symbols, mostly easy access to stdandard types

package Kephra::Base::Data::Type;
our $VERSION = 1.11;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;
use Kephra::Base::Data::Type::Util;
use Kephra::Base::Data::Type::Standard;
use Exporter 'import';
our @EXPORT_OK = qw/create_type check_type guess_type is_type_known/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

################################################################################
my $standard_types = Kephra::Base::Data::Type::Standard::init_store();
my $shared_types = Kephra::Base::Data::Type::Store->new('open'); 

sub standard    { $standard_types }
sub shared      { $shared_types }
sub state       { $shared_types->state }
sub restate     { $shared_types = Kephra::Base::Data::Type::Store->restate($_[0]) }

sub class_names { @Kephra::Base::Data::Type::Util::type_class_names }
################################################################################
sub is_known      { &is_type_known }
sub is_type_known {
    my ($type_name, $param_name, $all) = @_;
    $standard_types->is_type_known($type_name, $param_name) 
    or (defined $all and $shared_types->is_type_known($type_name, $param_name)) or 0;
}

sub create      { &create_type }
sub create_type {
    my ($type_def, $all) = @_;
    Kephra::Base::Data::Type::Util::create_type($_[0], $standard_types, (defined $all ? $shared_types : undef));
}

sub check      { &check_type }
sub check_type {
    my ($type_name, $value, $all) = @_;
    return $standard_types->check_basic_type($type_name, $value) if $standard_types->is_type_known($type_name);
    return $shared_types->check_basic_type($type_name, $value) if defined $all and $shared_types->is_type_known($type_name);
    "type $type_name is not known";
}

sub guess      { &guess_type }
sub guess_type {
    my ($value, $all) = @_;
    return $standard_types->guess_basic_type($value) unless defined $all;
    ($standard_types->guess_basic_type($value), $shared_types->guess_basic_type($value));
}
################################################################################

7;

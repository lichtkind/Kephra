use v5.20;
use warnings;

# organize type related symbols

package Kephra::Base::Data::Type;
our $VERSION = 0.3;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
use Kephra::Base::Data::Type::Store;
use Kephra::Base::Data::Type::Standard;
use Exporter 'import';
our @EXPORT_OK = qw/new_type check_type guess_type is_type_known/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
################################################################################

Kephra::Base::Data::Type::Standard::init();
my $standard_types = Kephra::Base::Data::Type::Store->new(''); 
my $shared_types = Kephra::Base::Data::Type::Standard::get_store();

sub standard { $standard_types }
sub shared   { $shared_types }
sub create_type {
    my ($type_name, $param_name) = @_;
}
sub check_type {
    my ($type_name, $value) = @_;
}
sub guess_type {
    my ($value) = @_;
}
sub is_type_known {
    my ($type_name, $param_name) = @_;

}

################################################################################

6;

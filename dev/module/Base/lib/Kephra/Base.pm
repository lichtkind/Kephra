use v5.20;
use warnings;
use Kephra::Base::Package;
use Kephra::Base::Data qw/:all/;
use Kephra::Base::Closure qw/:all/;

package Kephra::Base;
our $VERSION = 0.11;
use Exporter 'import';
our @EXPORT_OK = qw/new_counter new_closure/;
our %EXPORT_TAGS = (all  => [@EXPORT_OK]);


sub new_counter { new_closure('++$state', 0) }


'love and light';

use v5.20;
use warnings;

package Kephra::Base;
our $VERSION = 0.11;
use Exporter 'import';
our @EXPORT_OK = qw/new_counter date_time new_closure/;
our %EXPORT_TAGS = (all  => [@EXPORT_OK]);

use Kephra::Base::Package;
use Kephra::Base::Data qw/:all/;
use Kephra::Base::Closure qw/new_closure/;
use Kephra::Base::Class;

sub new_counter { new_closure('$state++', 0) }

'love and light';

use v5.20;
use warnings;
use Kephra::Base::Call;
use Kephra::Base::Data;
use Kephra::Base::Package;

package Kephra::Base;
our $VERSION = 0.01;
use Exporter 'import';
our @EXPORT_OK = qw/create_counter date_time/;
our %EXPORT_TAGS = (all  => [@EXPORT_OK]);


sub create_counter { Kephra::Base::Call->new('state $cc = 0; $cc++;') }

sub date_time {
    my @time = (localtime);
    sprintf ("%02u.%02u.%u", $time[3], $time[4]+ 1, $time[5]+ 1900),
    sprintf ("%02u:%02u:%02u:%03u", @time[2,1,0], int((gettimeofday())[1]/1_000));
}


'love and light';

use v5.20;
use warnings;
use Kephra::Base::Package;
use Kephra::Base::Data;
use Kephra::Base::Closure qw/new_call/;

package Kephra::Base;
our $VERSION = 0.01;
use Exporter 'import';
our @EXPORT_OK = qw/create_counter date_time new_call/;
our %EXPORT_TAGS = (all  => [@EXPORT_OK]);


sub create_counter { new_call('++$state', 0) }

sub date_time {
    my @time = (localtime);
    sprintf ("%02u.%02u.%u", $time[3], $time[4]+ 1, $time[5]+ 1900),
    sprintf ("%02u:%02u:%02u:%03u", @time[2,1,0], int((gettimeofday())[1]/1_000));
}


'love and light';

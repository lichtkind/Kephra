use v5.16;
use warnings;

use Kephra::Base::Class;
use Kephra::Base::Data;

package Kephra::Base;
our $VERSION = 0.01;


sub create_counter { Kephra::Base::Call->new('state $cc = 0; $cc++;') }

sub date_time {
    my @time = (localtime);
    sprintf ("%02u.%02u.%u", $time[3], $time[4]+ 1, $time[5]+ 1900),
    sprintf ("%02u:%02u:%02u:%03u", @time[2,1,0], int((gettimeofday())[1]/1_000));
}

'love and light';

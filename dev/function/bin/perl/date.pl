use v5.16;
use warnings;
use Time::HiRes qw/gettimeofday/;

my @time = (localtime);
say sprintf "[%02u:%02u:%02u:%02u] %02u.%02u.%u ",
    @time[2,1,0], int((gettimeofday())[1]/10_000), $time[3], $time[4]+ 1, $time[5]+ 1900;

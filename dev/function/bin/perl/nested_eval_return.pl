use v5.14;
use warnings;
use Benchmark;

my $ret; eval '$ret = sub { shift }';
my $wrap; eval '$wrap = sub { $ret->( shift ) }';

say "inner evaled sub is a codref: $ret, has to return 1 = ", $ret->(1);
say "outer evaled sub is a codref: $wrap, has to return 2 = ", $wrap->(2);

my $filter; eval '$filter = sub {my $h = shift; $h->{"h"}." ".localtime }';
say "filter drops time -> should be two different values: ",$filter->({h => 3}),' ',$filter->({h => 4});
use v5.16;
use warnings;

BEGIN { unshift @INC, 'bin/perl', '.'}

my $r = 'Require.pm';

require $r;
#use Require;

say  Require::test();
say 'there shoult only be a t above this text';
say  'path: ',$INC{$r};


exit(0);

use v5.14;
use warnings;
use Benchmark;

package Kephra::API;
sub warning { 'old' }


package main;

my $sub_name = 'Kephra::API::warning';
my $sub_ref = sub { 'new' };

no strict 'refs';
no warnings;
say *{$sub_name}{CODE};
*$sub_name = $sub_ref;
say *{$sub_name}{CODE};

use strict 'refs';
use warnings;
say $sub_ref;
say "second should be different from first and same as third ref";
say "and outut should be new :";
say $sub_ref->();

exit(0);

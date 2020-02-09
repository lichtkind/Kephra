#!usr/bin/perl
use v5.16;
use warnings;

# check if undef works as valid return value

sub get_undef      { return undef }
sub transmit_undef { return get_undef() }

say 'return transports undef' unless defined transmit_undef();

exit(0);

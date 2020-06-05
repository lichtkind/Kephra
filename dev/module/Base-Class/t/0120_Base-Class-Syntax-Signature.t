#!/usr/bin/perl -w
use v5.20;
use warnings;
use experimental qw/switch/;
use Test::More tests => 40;

BEGIN { unshift @INC, 'lib', '../lib', '.', 't'}
use Kephra::Base::Class::Syntax::Signature;


my $a = Kephra::Base::Class::Syntax::Signature::split_args('  ');
say $a;
say int @$a;
say "$a->[0]";
#say int @{$a->[0]};
#say ".$a->[0][0].";
#say ".$a->[0][0].$a->[0][1].";
#say ".$a->[1][0].";

exit 0;
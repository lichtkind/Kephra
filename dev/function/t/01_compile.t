#!/usr/bin/perl -w

use v5.12;
use strict;
use Cwd;
use File::Find qw(find);
use File::Spec;
use Test::More;


#say Cwd::cwd();
my $dir = 'bin';
my @func_protos; # func_protos

find( sub {
   my $script = $File::Find::name;
   return if -d '../'.$script;
   return if substr($script, -2) ne 'pl';
   push @func_protos, $script;
}, $dir);

my $tests = 1 + scalar @func_protos;
plan tests => $tests;
#plan tests => 10;

ok( $] >= 5.0014, 'Your perl is new enough' );
#is( system("perl -Ibin/perl -c bin/perl/$_.pl"), 0, 'script runs') for qw/caller date import nested_eval_return objrw ref symbol_table undef use_strict/;

for (@func_protos) {
    is( system('perl -I'.(File::Spec->splitpath( $_ ))[1].' -c '.$_), 0, $_.' runs');
}


exit(0);


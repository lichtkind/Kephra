#!/usr/bin/perl -w

use v5.16;
use warnings;
use Test::More;
use File::Spec;
use Cwd;

BEGIN { unshift @INC, 'lib'}

my $module_proto_path = File::Spec->catdir('..','module');
my $overview_path = 'lib';
chdir '..' unless -d 't';

my (%new_module, %all_module, @proto, %proto_module, $pnr, $tests);
open my $FH, '<', File::Spec->catfile($module_proto_path,'index.txt');
while (<$FH>){
    last if substr($_,0,1) eq "=";
    next if substr($_,0,1) eq "#";
    if (substr($_,0,1)eq "-" and %new_module){ 
        $pnr++;
        die "group of modules in modules/index.txt has no leader (proto name)" if $pnr != @proto;
        my $proto_path = $proto[-1];
        $proto_path = File::Spec->catdir($module_proto_path, $proto_path, 'lib');
        for (keys %new_module){
            die "package introduced in two module proto" if $all_module{$_};
            my $ret = `perl t/list_pkg_methods.pl $_ lib`;
            $all_module{$_}{'overview'} = $ret;
        }
        for (keys %all_module){
            $tests++;
            $proto_module{$proto[-1]}{$_}++;
            $all_module{$_}{$proto[-1]} = `perl t/list_pkg_methods.pl $_ $proto_path`;
        }
        %new_module = ();
    }
    next if index($_, '::') < 0;
    /(\w+(?:::\w+)+)/;
    my $m = $1;
    $new_module{$m}++;
    if (/^\s*-/){
        $m =~ s/::/-/g;
        $m = substr $m, 7;   # cut 'Kephra::'
        push @proto, $m ;
    }#  say "$proto[-1], $m";
}
close $FH;

plan tests => $tests;

for my $proto (@proto){
    for my $module (keys %{$proto_module{$proto}}){
        # say "------ $module, ", $all_module{$module}{'overview'}, ' ||| ', $all_module{$module}{$proto};
        ok( in($all_module{$module}{'overview'}, $all_module{$module}{$proto}), "$proto : $module" );
    }
}


sub in {
    my ($got, $expected) = @_;
    my %modules;
    $modules{$_}++ for split ' ', $expected;
    for (split ' ', $got){
        die " got $got, expected $expected" unless $modules{$_};
    }
    1;
}

exit (0);

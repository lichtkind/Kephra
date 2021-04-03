#!/usr/bin/perl -w

use v5.18;
use warnings;
use Test::More;
use File::Spec;
use File::Find;
use Cwd;

BEGIN { unshift @INC, 'lib'}

my (%overview_pkg, %module_pkg, $tests);
my $all_module_proto_path = File::Spec->catdir('..','module');
my $overview_lib_path = File::Spec->catdir('lib','Kephra');
chdir '..' unless -d 't';

opendir my $moduleDH, $all_module_proto_path or die "can not open $all_module_proto_path";
while (readdir $moduleDH){
    next unless /^[A-Z]/;
    my $module_proto_path = File::Spec->catdir($all_module_proto_path, $_);
    opendir my $stageDH, $module_proto_path or die "can not open $module_proto_path";
    while (readdir $stageDH){
        next if /^\./;
        my $module_lib_path = File::Spec->catdir($module_proto_path, $_, 'lib', 'Kephra');
        find( sub { 
            return if -d $_;
            my $file = substr $File::Find::name, length($module_lib_path)+1;
            $module_pkg{$file} = {};
            open my $FH, '<', $_ or die "can not open file $_";
            while (<$FH>){
                next unless /^\s*sub\s+(\w+)/;
                next if substr($1, 0, 1) eq '_';
                $module_pkg{$file}{$1}++;
            }
        }, $module_lib_path);

    }
}

for my $pkg (keys %module_pkg){
    $tests += 2;
    $tests++ for keys %{$module_pkg{$pkg}};
}
plan tests => $tests;

for my $pkg (keys %module_pkg){
    my $file = File::Spec->catdir( $overview_lib_path, $pkg );
    ok( -r $file, "package $pkg exists");
    
    my %sub;
    open my $FH, '<', $file or die "can not open file $file";
    while (<$FH>){
        next unless /^\s*sub\s+(\w+)/;
        $sub{$1}++;
    }

    for my $sub (keys %{$module_pkg{$pkg}}){
        ok( exists $sub{$sub}, "sub $pkg\::$sub exists");
    }
}

use lib 'lib';
require Kephra;
for my $pkg (keys %module_pkg){
    my $file = File::Spec->catdir( 'Kephra', $pkg );
    ok( exists $INC{$file}, "package $file was loaded");
}

exit (0);

__END__

open my $FH, '<', File::Spec->catfile('module', 'index.txt');
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


# just starter, does almost nothing

use v5.16;
use FindBin qw($Bin);
use File::Spec;

BEGIN { unshift @INC, File::Spec->catdir($Bin,'../lib') }

use Kephra;

my $option = shift;
my $pattern = shift;


if      ($option eq '--modules') {
    for (sort keys %INC) { 
        s|/|::|g; 
        say substr($_, 0, -3) if not $pattern or /$pattern/; 
    }
} elsif ($option eq '--methods') {
    no strict 'refs';
    my @mods;
    for (sort keys %INC) {
        s|/|::|g;
        push @mods, substr( $_, 0, -3);
    }
    for my $module (@mods) {
        next if defined $pattern and $module !~ /$pattern/;
        say $module;
        say "    $_" for keys %{$module.'::'};
    }
} else {
    say "$Kephra::NAME $Kephra::VERSION";
    say '... compiles with ',(scalar  keys %INC), ' modules loaded';
    say '... use option --modules [pattern] or --methods [pattern] to see what was loaded';
}

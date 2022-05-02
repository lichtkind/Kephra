# just starter, does almost nothing

use v5.16;
use FindBin qw($Bin);
use File::Spec;
use Cwd;

my $option = shift;
my $pattern = shift;
my $indent_size = 4;
my %seen_pkg;
my $lib_dir;

BEGIN { 
    $lib_dir = File::Spec->catdir($Bin, '../lib');
    unshift @INC, $lib_dir;
}
use Kephra;



if      ($option eq '--modules')  {
    for (sort keys %INC) { 
        s|/|::|g; 
        say substr($_, 0, -3) if not $pattern or /$pattern/; 
    }
} elsif ($option eq '--moduse')  { print_mod_use ('Kephra', 1, $pattern)
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
    say '... use option --moduse to see dep order';
}


sub print_mod_use {
    my ($package, $level, $patern, $clean) = @_;
    my $file = $package;
    $file =~ s|::|/|g;
    $file =  File::Spec->catdir( $lib_dir, $file.'.pm' );
    my $indent = (' ' x ($level * $indent_size));
    my $entry = $package;
    if (defined $clean and $clean){
        my @part = split '::', $entry;
        say "$indent :: $part[-1]";
    } else {
        say "$indent - $entry";
    }
    open my $FH, '<', $file or die "could not open $file: $!";
    while (<$FH>){
        chomp;
        next unless /^(use|require)\s+([\w:]+)/;
        my $pkg = $2;
        my $k = substr $pkg, 0, 6;
        my $fl = substr $pkg, 0, 1;
        $seen_pkg{$pkg}++;
        next unless uc $fl eq $fl and $seen_pkg{ $pkg } == 1;
        next if defined $pattern and $pkg !~ /$pattern/;
        if ($k eq 'Kephra'){ print_mod_use( $pkg, $level+1, $pattern, index($pkg, $package) == 0 ) }
#        else               { say "$indent   - $pkg" }
    }
}


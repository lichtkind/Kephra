use v5.16;
no strict 'refs';
use Cwd;

BEGIN { unshift @INC, '.' }

my $pkg = shift;
my $dir = shift;
chdir $dir if defined $dir and -d $dir;

$pkg = substr($pkg,0,-3) if substr($pkg, -3) eq '.pm';
my @m = eval "require $pkg;  return sort keys %".$pkg.'::';
die $@ if $@;

my @clean;
for my $m (@m) {
    next if $m eq 'import';
    next if $m eq uc $m;
    next if substr ($m, -2) eq '::';
    next if substr($m,0,1) eq '_';
    push @clean, $m;
}
print(join(' ', @clean));

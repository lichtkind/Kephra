use v5.16;
no strict 'refs';

BEGIN { unshift @INC, '.' }

# loads package of gien name and displays methods

my $pkg = shift // 'Base';
$pkg = substr($pkg,0,-3) if substr($pkg, -3) eq '.pm';
require "$pkg.pm";

#say join(',', sort keys *{"$pkg"."::"}{HASH});
no strict 'refs';
say for sort keys %{*{$pkg."::"}{HASH}};

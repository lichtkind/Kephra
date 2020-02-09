use v5.16;
no strict 'refs';

BEGIN { unshift @INC, '.' }

my $pkg = shift;
$pkg = substr($pkg,0,-3) if substr($pkg, -3) eq '.pm';
require "$pkg.pm";

say join(',', sort keys *{"$pkg"."::"}{HASH});

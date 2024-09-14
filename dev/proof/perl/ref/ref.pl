use v5.14;

my (%a, %b);
$a{'a'} = 1;
$b{'b'} = \$a{a}; # $b{'b'}{'a'} == 1

say "value   : ",  $a{a}; 
say "stored ref : ",  $b{b}; 
say "ref content   : ",  ${$b{'b'}}; 

delete $a{a}; 

say "del original: ", $a{a};
say "stored ref : ",  $b{b}; 
say 'ref content definied' if defined ${$b{b}};
say 'ref content not defined' unless defined ${$b{b}};

__END__

refs


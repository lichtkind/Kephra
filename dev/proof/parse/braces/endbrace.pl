use v5.16;
use warnings;

my $bsp1 = '01{3{{}}8}0{2';
my $bsp2 = '0{2{{}}{}9}12';

# recognize matching braces

say 'should output 9 and 10';
say closing_pos($bsp1);
say closing_pos($bsp2);

sub closing_pos {
   my ($str, $bcc, $lpos, $rpos) = (shift, 0);
   #say '-'x80;  # say "$bcc: $lpos - $rpos";
   $lpos = index($str,'{',0);
   $rpos = index($str,'}',0);
   while (1){
       if ($bcc){ $rpos = index($str,'}',$rpos+1);
                  if ($rpos == -1) {return -1} else {$bcc--}}
       else {     $lpos = index($str,'{',$lpos+1);
                  if ($lpos == -1 or $lpos > $rpos) {return $rpos} else {$bcc++}}
   }
}
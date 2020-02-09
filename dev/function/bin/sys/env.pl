use v5.12;

my ($k, $v);
say "Perl $]";
say "OS $^O";
say "$k: \t\t $v" while ($k, $v) = each %ENV;
say "$k: \t\t $v" while ($k, $v) = each %INC;
use v5.14;

package Strict;

say for 0x00000002, ' ', 0x00000200,' ', 0x00000400;
say '';

$^H = 1538;  # 2 | 512 | 1024;

1;

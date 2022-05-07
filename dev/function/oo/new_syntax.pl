use v5.16;
use warnings;
use lib '.';
use OOKeyWords;

my $obj = C->new();

say 'created instance from class with new keywords: ', $obj;
say 'object has right class: ', $obj->isa('C');
say 'inserted parent class: ', $obj->isa('Base');
say 'have methods of parent class: ', $obj->is_base();
say 'inserted method has result: ', before();
say 'other inserted method g has result: ', C::before();

class C 2; method new { bless {} } 
class D 3; method new2 { bless {} } 

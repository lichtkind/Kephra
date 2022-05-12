use v5.20;
use warnings;

# definitions and store of standard data type checker objects

package Kephra::Base::Data::Type::Standard;
our $VERSION = 2.6;
use Kephra::Base::Data::Type::Namespace;

our @basic_type_definitions;
our @parametric_type_definitions;
our %basic_type_shortcut;
our %parametric_type_shortcut;
our @forbidden_shortcuts;

sub init_store        {}   #    -->  .type_store
sub store             {}   #    -->  .type_store

6;

__END__


value   $
str     ~
bool    ?
num     +
int_pos N
int     Z


array_ref    @
hash_ref     % 
code_ref     & 
any_ref      \ 
KBOS type    T

KBOS object  .
other object !




index I
@N
%~
!Wx::App

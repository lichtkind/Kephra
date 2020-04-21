use v5.20;
use warnings;

# data type object that compiles a coderef (type checker) and can serialize

package Kephra::Base::Data::Type::Simple;

sub new                {} # ~type ~help ~code ~file ~package - $default .parent_type ~shortcut --> .type | ~errormsg
sub restate            {} # %state                                                             --> .type | ~errormsg
sub state              {} # .type                 --> %state

sub get_default_value  {} # .type                 --> $default
sub get_shortcut       {} # .type                 --> ~shortcut
sub get_callback       {} # .type                 --> &callback

sub is_standard        {} # .type                 --> ?
sub is_owned           {} # .type ~package ~file  --> ?
sub check              {} # .type $val            --> ~errormsg

1;

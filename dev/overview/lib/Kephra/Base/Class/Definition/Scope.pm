use v5.20;
use warnings;

# namespace constants, paths & priority logic

package Kephra::Base::Class::Definition::Scope;
our $VERSION = 1.5;



sub all_scopes         {} #                             --> @~name
sub is_scope           {} # ~scope                      --> ?
sub method_scopes      {} #                             --> @~name
sub is_method_scope    {} # ~scope                      --> ?
sub is_first_tighter   {} # ~scopeA ~scopeB             --> ?

sub cat_method_paths   {} # ~class ~method              --> @~mspath
sub cat_hook_path      {} # ~class ~method ~hook ~hname -->  ~hspath
sub cat_arguments_path {} # ~class ~method ~arg         -->  ~mapath
sub cat_attribute_path {} # ~class ~attribute           -->  ~capath

1;

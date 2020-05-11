use v5.20;
use warnings;

# namespace constants, paths & priority logic

package Kephra::Base::Class::Scope;
our $VERSION = 1.5;

sub is_first_tighter   {}  # ~scopeA ~scopeB       --> ?

sub cat_method_paths   {} # ~class ~method      --> @~mspath
sub cat_hook_path      {} # ~class ~method      -->  ~hspath
sub cat_arguments_path {} # ~class ~method      -->  ~mapath
sub cat_attribute_path {} # ~class ~attribute   -->  ~capath

1;

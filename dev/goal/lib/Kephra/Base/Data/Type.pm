use v5.20;
use warnings;

# organize type related symbols, mostly easy access to stdandard types

package Kephra::Base::Data::Type;
our $VERSION = 1.5;

use Kephra::Base::Data::Type::Checker;

sub state         {} # %state           -->
sub restate       {} #                  --> %state

sub standard      {} #                  -->  .type_store
sub shared        {} #                  -->  .type_store
sub class_names   {} #                  --> @~type_class

sub is_known      {} #                                          alias:
sub is_type_known {} # ~type|[~type ~param] ?shared @.type_store    --> ?

sub resolve_shortcut {} #                                       alias:
sub resolve_type_shortcut{} # ~kind ~shortcut ?shared @.type_store      --> ~type

sub create        {} #                                          alias:
sub create_type   {} # %type_def ?shared @.type_store          -->  .type

sub check         {} #                                          alias:
sub check_type    {} # ~type $value  ?shared  @.type_store     -->  ~errormsg

sub guess         {} #                                          alias:
sub guess_type    {} #       $value  ?shared  @.type_store     --> @~type

7;

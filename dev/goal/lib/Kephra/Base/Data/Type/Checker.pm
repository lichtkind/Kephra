use v5.20;
use warnings;

# extendable collection of simple and parametric type objects + dependency resolver
# multiple parametric types with same name and different parameters must have same owner and shortcut (basic type shortcuts have own name space)

package Kephra::Base::Data::Type::Checker;
our $VERSION = 0.10;

use Kephra::Base::Data::Type::Standard;

sub new                      {} # - 'open'                    --> ._       open store can not finalized
sub state                    {} # ._                          --> %state   dump all active types data
sub restate                  {} # %state                      --> ._       recreate all type checker from data dump

sub add_type_set             {} # _ .set                      --> ~errormsg
sub remove_type_set          {} # _ ~set_name                 --> ~errormsg
sub get_type_set             {} # _ ~set_name                 --> .set|~errormsg
sub type_set_names           {} # _                           --> @~set_name
 
sub is_type_known            {} # _ ~type - ~param            --> ?
sub is_type_owned            {} # _ ~type - ~param            --> ?
sub get_type                 {} # _ ~type - ~param            --> .type|~errormsg
sub get_shortcut             {} # _ ~kind ~type               --> ~shortcut|~errormsg       # ~kind = 'simple'|'para[meter]'
sub resolve_shortcut         {} # _ ~kind ~shortcut           --> ~full_name|undef

sub get_type_checker         {} # _ ~typeID                   --> &checker|~errormsg
sub check_data_against_type  {} # _ ~typeID $val -- $pval     -->  ~errormsg
sub guess_basic_type         {} # _ $val                      --> @~type

7;

use v5.20;
use warnings;

# extendable collection of simple and parametric type objects + deps resolver
#      serialize type keys: object, shortcut, file, package

package Kephra::Base::Data::Type::Standard;
our $VERSION = 0.5;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;

sub new               {} #            --> .tstore
sub state             {} #            --> %state          dump all active types data
sub restate           {} # %state     --> .tstore         recreate all type checker from data dump

sub new_simple_type   {} # .tstore ~type ~help            ~code - .parent|~parent   $default --> ~errormsg 
sub new_param_type    {} # .tstore ~type ~help %parameter ~code   .parent|~parent - $default --> ~errormsg
                         #                     .type|%{.type|~type - ~name $default }      
sub add_type          {} # .tstore ~type ~shortcut         --> ~errormsg
sub remove            {} # .tstore ~type - ~param          --> ~errormsg
sub finalize          {} # .tstore                         --> ?

sub get_type          {} # .tstore ~type - ~param          -->  ~errormsg
sub get_shortcut      {} # .tstore ~type - ~kind           -->  ~errormsg
sub resolve_shortcut  {} # .tstore ~shortcut - ~param      -->  ~type
sub list_names        {} # .tstore - ~kind ~name           --> @~type|@~ptype|@~param # ~kind = 'simple'|'para[meter]'
sub list_shortcuts    {} # .tstore - ~kind                 --> @~shortcut

sub is_known          {} # .tstore ~type - ~param          --> ?
sub is_owned          {} # .tstore ~type - ~param          --> ?

sub check_simple      {} # .tstore ~type $val              -->  ~errormsg             # = "reason $val"
sub check_param       {} # .tstore ~type ~param $val $pval -->  ~errormsg    
sub guess_simpletype  {} # .tstore $val                    --> @~type                 # guess simple type

1;

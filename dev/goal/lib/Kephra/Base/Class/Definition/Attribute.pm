use v5.20;
use warnings;

# switch for kinds of attribute definitions

package Kephra::Base::Class::Definition::Attribute;
our $VERSION = 0.5;

use Kephra::Base::Class::Definition::Attribute::Data;
use Kephra::Base::Class::Definition::Attribute::Delegating;
use Kephra::Base::Class::Definition::Attribute::Wrapping;


sub new      {} # ~pkg ~name %properties       --> ._| ~errormsg          ._ = attr_data|deleg|wrap


1;

__END__


kind = data | delegating | wraping
help = ~longhelp
type = name | !Wx:: |


################################################################################
sub get_kind        {$kind}
sub get_help        {$_[0]->{'help'}}
sub get_class       {$_[0]->{'class'}}
sub get_default_args{$_[0]->{'default'}}
sub get_build_args  {$_[0]->{'build'}}
sub is_lazy         {$_[0]->{'lazy'}}
sub accessor_names  {@{ $_[0]->{'methods'}} }
sub auto_accessors  {$_[0]->{'auto'}}              # name => scope | [getscope, original_name]

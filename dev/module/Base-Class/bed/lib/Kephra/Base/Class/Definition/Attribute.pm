use v5.20;
use warnings;

# validate and serialize attribute definition

package Kephra::Base::Class::Definition::Attribute;
our $VERSION = 1.0;

use Kephra::Base::Data::Type;
use Kephra::Base::Class::Definition::Attribute::Data;       # raw data
use Kephra::Base::Class::Definition::Attribute::Delegating; # kbos objects
use Kephra::Base::Class::Definition::Attribute::Wrapping;   # foreign objects

sub new {        # ~pkg ~name %properties       --> ._| ~errormsg
    my ($pkg, $name, $attr_def) = (@_);
    return "attribute definition needs an identifier (a-zA-Z0-9_) as first argument" if Kephra::Base::Data::Type::standard->check_basic_type('identifier', $name);
    my ($error_start, $type_def) = ("attribute $name");
    return "$error_start got no property hash to define itself" unless ref $attr_def eq 'HASH';
    return "$error_start needs a descriptive 'help' text of more than 5 character" unless exists $attr_def->{'help'} and length $attr_def->{'help'} > 5;
    $attr_def->{'name'} = $name;
    if    (exists $attr_def->{'delegate'} or exists $attr_def->{'auto_delegate'}) {Kephra::Base::Class::Definition::Attribute::Delegating->new($attr_def)}
    elsif (exists $attr_def->{'get'} or exists $attr_def->{'auto_get'})           {Kephra::Base::Class::Definition::Attribute::Data->new($attr_def)}
    elsif (exists $attr_def->{'wrap'})                                            {Kephra::Base::Class::Definition::Attribute::Wrapping->new($attr_def)}
    else  {return "definition of attribute $name lacks accessor name in (auto_)get, (auto_)delegate or wrap property (the yre exclusive!)"}
}

1;

use v5.20;
use warnings;

# validate and serialize attribute definition
# 0102_Base-Class-Definition-Attribute-Raw.t

package Kephra::Base::Class::Definition::Attribute;
our $VERSION = 1.0;

use Kephra::Base::Data::Type; #?
use Kephra::Base::Class::Definition::Scope;
use Kephra::Base::Class::Definition::Attribute::Native;     # raw data
use Kephra::Base::Class::Definition::Attribute::Delegating; # kbos objects
use Kephra::Base::Class::Definition::Attribute::Wrapping;   # foreign objects

sub new {        # ~pkg ~name %properties       --> ._| ~errormsg
    my ($pkg, $name, $attr_def) = (@_);
    return "attribute definition needs an identifier (a-zA-Z0-9_) as first argument" 
        if Kephra::Base::Data::Type::standard->check_basic_type('identifier', $name);
    my ($error_start, $type_def) = ("definition of attribute $name");
    return "$error_start got no property hash to define itself" unless ref $attr_def eq 'HASH';
    return "$error_start needs a descriptive 'help' text of more than 10 character"
        unless exists $attr_def->{'help'} and length $attr_def->{'help'} > 10;
    $attr_def->{'name'} = $name;
    $attr_def->{'kind'} = 'native' unless exists $attr_def->{'kind'}; # default to native kind of attribute
    my $kind = $attr_def->{'kind'};
    if    ($kind eq 'native')    {Kephra::Base::Class::Definition::Attribute::Raw->new($attr_def)}
    elsif ($kind eq 'delegating'){Kephra::Base::Class::Definition::Attribute::Delegating->new($attr_def)}
    elsif ($kind eq 'wrapping')  {Kephra::Base::Class::Definition::Attribute::Wrapping->new($attr_def)}
    else                         {"$error_start lacks valid 'kind', has to be: 'native' or 'delegating' or 'wrapping'"}
}

################################################################################
sub state       { $_[0] }
sub restate     { bless shift }
################################################################################
sub kind        {$_[0]->{'kind'}}
sub help        {$_[0]->{'help'}}
sub type        {$_[0]->{'type_class'}}
sub class       {$_[0]->{'type_class'}}
sub build_code  {$_[0]->{'build'}}      # can be alt default
sub is_lazy     {$_[0]->{'lazy'}}
sub getter_name {$_[0]->{'getter_name'}}
sub getter_scope{$_[0]->{'getter_scope'}}
sub setter_name {$_[0]->{'setter_name'}}
sub setter_scope{$_[0]->{'setter_scope'}}

1;

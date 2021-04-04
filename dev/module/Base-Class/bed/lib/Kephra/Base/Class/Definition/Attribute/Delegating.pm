use v5.20;
use warnings;

# data structure holding a definition of a KBOS attribute that holds a KBOTS object

package Kephra::Base::Class::Definition::Attribute::Delegating;
our $VERSION = 1.41;
my $kind = 'delegating';
my $default_scope = 'private';
################################################################################
sub new {        # ~pkg %attr_def            --> ._ | ~errormsg
    my ($pkg, $attr_def) = (@_);
    return "need a property hash to create a delegating attribute definition" unless ref $attr_def eq 'HASH';
    my $error_start = "$kind attribute ".(exists $attr_def->{name} ? $attr_def->{name} : '');
    my $self = {methods => [], auto => {}, lazy => 0};
    for (qw/name help class/) {
        return "$error_start lacks property '$_'" unless exists $attr_def->{$_};
        return "$error_start property '$_' can not be a reference"  if ref $attr_def->{$_};
        return "$error_start property '$_' can not be empty"  unless $attr_def->{$_};
        $self->{$_} = delete $attr_def->{$_};
    }
    if    (exists $attr_def->{'default_args'})   {$self->{'default'} = delete $attr_def->{'default_args'} }
    elsif (exists $attr_def->{'lazy_args'})      {$self->{'default'} = delete $attr_def->{'lazy_args'}; $self->{'lazy'} = 1; }
    elsif (exists $attr_def->{'build_args'})     {$self->{'build'}   = delete $attr_def->{'build_args'} }
    elsif (exists $attr_def->{'lazy_build_args'}){$self->{'build'}   = delete $attr_def->{'lazy_build_args'}; $self->{'lazy'} = 1; }
    else  {return "constructor arguments of $error_start are missing. Use property 'default_args' or 'lazy_args' or '[lazy_]build_args'."}

    return "constructor arguments of $error_start have to be in an array or (preferably) an hash."
        if exists $self->{'default'} and ref $self->{'default'} ne 'ARRAY' and ref $self->{'default'} ne 'HASH';
    return "build code for the constructor argument values of $error_start has to be in an array or (preferably) an hash."
        if exists $self->{'build'} and ref $self->{'build'} ne 'ARRAY' and ref $self->{'build'} ne 'HASH';

    return "$error_start lacks property 'delegate' or 'auto_delegate'" unless exists $attr_def->{'delegate'} or exists $attr_def->{'auto_delegate'};
    push @{$self->{'methods'}}, @{delete $attr_def->{'delegate'}} if ref $attr_def->{'delegate'} eq 'ARRAY';
    push @{$self->{'methods'}},   delete $attr_def->{'delegate'}  if not ref $attr_def->{'delegate'} and exists $attr_def->{'delegate'};

    return "$error_start property 'auto_delegate' has to be defined by an hash: auto_delegate => {method => 'scope'} or method => { to => 'attr_method', scope => 'public'} or auto_delegate => method (default access scope)" 
        if exists $attr_def->{'auto_delegate'} and ref $attr_def->{'auto_delegate'} and ref $attr_def->{'auto_delegate'} ne 'HASH';
    return "$error_start property 'auto_get' has to be defined by an hash: auto_get => {method => scope} or auto_get => method (default access scope)" 
        if exists $attr_def->{'auto_get'} and ref $attr_def->{'auto_get'} and ref $attr_def->{'auto_get'} ne 'HASH';
    $self->{'auto'} = delete $attr_def->{'auto_delegate'} if ref $attr_def->{'auto_delegate'} eq 'HASH';
    for (keys %{$self->{'auto'}}){
        if (not ref $self->{'auto'}{$_})  { 
            $self->{'auto'}{$_} = { delegate_to => $_, scope => ($self->{'auto'}{$_}||$default_scope) } 
        } elsif (ref $self->{'auto'}{$_} eq 'HASH' and (exists $self->{'auto'}{$_}{'to'} or exists $self->{'auto'}{$_}{'scope'} )) {
            $self->{'auto'}{$_} = { delegate_to => $self->{'auto'}{$_}{'to'}, scope => $self->{'auto'}{$_}{'scope'}} 
        } else {
            return "autogenerated method '$_' of $error_start has an invalid definition. It has to be {method => scope} or {method => {to => attribute_method, scope => 'name'}}";
        }
    }
    $self->{'auto'}{delete $attr_def->{'auto_delegate'}} = {delegate_to => $attr_def->{'auto_delegate'}, scope => $default_scope}
        if exists $attr_def->{'auto_delegate'} and not ref $attr_def->{'auto_delegate'};
    $self->{'auto'}{delete $attr_def->{'auto_get'}} = {get => 'access'} if exists $attr_def->{'auto_get'} and not ref $attr_def->{'auto_get'};
    if (ref $attr_def->{'auto_get'} eq 'HASH'){
        $self->{'auto'}{$_}{'get'} = $attr_def->{'auto_get'}{$_} for keys %{$attr_def->{'auto_get'}};
        delete $attr_def->{'auto_get'};
    }

    for (keys %$attr_def){ return "$error_start has the illegal, malformed or effectless property '$_'"  }
    bless $self;
}
################################################################################
sub state       { $_[0] }
sub restate     { bless shift }
################################################################################
sub get_kind        {$kind}
sub get_help        {$_[0]->{'help'}}
sub get_class       {$_[0]->{'class'}}
sub get_default_args{$_[0]->{'default'}}
sub get_build_args  {$_[0]->{'build'}}
sub is_lazy         {$_[0]->{'lazy'}}
sub accessor_names  {@{ $_[0]->{'methods'}} }
sub auto_accessors  {$_[0]->{'auto'}}              # name => scope | [getscope, original_name]

1;
__END__

delegating attribute name  => {help => '',                # help = long name/description for help messages
                              class => 'Kephra::...',     # class of attribute (has to be a KBOS class)
                 |         delegate => del_name|[name,..];# delegator method that get access to the attribute
                 |    auto_delegate => {dname => 'scope'} # auto generate method 'self->dname' which maps to 'attr->dname'
                                       {dname => { to => 'orig', scope => 'public'}} # auto generate method 'self->dname' which maps to 'attr->orig', default scope is access
               ?          auto_get  => {name => 'scope'}; # autogenerated getter name
               ?|      default_args => [$val]|{attr=>$val}# args to construct attribute object (positional [] or named {}, first is method name)
               ?|         lazy_args => [$val]|{attr=>$val}# default_args  lazy version
               ?| [lazy_]build_args => ['code']|{a=>'cod'}# eval to build args values

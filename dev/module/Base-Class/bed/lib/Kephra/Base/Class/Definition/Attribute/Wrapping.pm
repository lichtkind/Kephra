use v5.20;
use warnings;

# data structure holding a definition of a KBOTS attribute that holds a none KBOS object

package Kephra::Base::Class::Definition::Attribute::Wrapping;
our $VERSION = 1.1;
my $kind = 'wrapping';
################################################################################
sub new {        # ~pkg %attr_def            --> ._ | ~errormsg
    my ($pkg, $attr_def) = (@_);
    return "need a property hash to create a wrapping attribute definition" unless ref $attr_def eq 'HASH';
    my $error_start = "$kind attribute ".(exists $attr_def->{name} ? $attr_def->{name} : '');
    my $self = {methods => [], auto => {}, lazy => 0};
    for (qw/name help class/) {
        return "$error_start lacks property '$_'" unless exists $attr_def->{$_};
        return "$error_start property '$_' can not be a reference"  if ref $attr_def->{$_};
        return "$error_start property '$_' can not be empty"  unless $attr_def->{$_};
        $self->{$_} = delete $attr_def->{$_};
    }
    return "$error_start lacks property 'wrap'" unless exists $attr_def->{'wrap'};
    if (ref $attr_def->{'wrap'} eq 'ARRAY') { $self->{'methods'} =  delete $attr_def->{'wrap'}  }
    elsif (not ref $attr_def->{'wrap'})     { $self->{'methods'} = [delete $attr_def->{'wrap'}] }
    else { return "methods of $error_start (property 'wrap') has to be a method name (string) or an array (reference) with method names"; }

    $self->{'require'} = delete $attr_def->{'require'} if exists $attr_def->{'require'} and $attr_def->{'require'} and not ref $attr_def->{'require'};

    if   (exists $attr_def->{'build'})     {$self->{'build'} = delete $attr_def->{'build'} }
    elsif(exists $attr_def->{'lazy_build'}){$self->{'build'} = delete $attr_def->{'lazy_build'}; $self->{'lazy'} = 1; }
    else {return "build code for $error_start is missing. Use property 'build' or 'lazy_build'." }
    return "code to construct the attribute has to be a string" if ref $self->{'build'};

    for (keys %$attr_def){ return "$error_start has the illegal, malformed or effectless property '$_'"  }
    bless $self;
}
################################################################################
sub state   { $_[0] }
sub restate { bless shift }
################################################################################
sub get_kind    { $kind }
sub get_help    {$_[0]->{'help'}}
sub get_build   {$_[0]->{'build'}}
sub is_lazy     {$_[0]->{'lazy'}}
sub accessor_names  {@{ $_[0]->{'methods'}} }
sub get_requirement { $_[0]->{'require'} // $_[0]->{'class'} }

1;
__END__

wrapping attribute name => { help  => '',                 # short explaining text for better ~errormsg
                            class  => 'Kephra::...',      # class of attribute (can be any)
                  ?        require => 'Module'            # 1 if require class
                             wrap  => [wrapper_name]|name # claim this to be implemented wrapper method as belonging to this attribute
                  ?|       default => $val                # default value when its different from the type ones
                   |  [lazy_]build => 'code'              # code snippets to run (lazily) create $attr object and bring it into init state
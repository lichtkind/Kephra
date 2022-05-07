use v5.20;
use warnings;

# data structure holding a definition of a KBOS attribute that holds a none KBOS object
# 0104_Base-Class-Definition-Attribute-Wrapping.t

package Kephra::Base::Class::Definition::Attribute::Wrapping;
our $VERSION = 1.1;
our @ISA = 'Kephra::Base::Class::Definition::Attribute';


sub new {        # ~pkg %attr_def            --> ._ | ~errormsg
    my ($pkg, $attr_def) = (@_);
    return "need a property hash to create a wrapping attribute definition" unless ref $attr_def eq 'HASH';
    my $error_start = "$kind attribute ".(exists $attr_def->{name} ? $attr_def->{name} : '');
    my $self = {methods => [], auto => {}, lazy => 0, require => 0};
    for (qw/name help class/) {
        return "$error_start lacks property '$_'" unless exists $attr_def->{$_};
        return "$error_start property '$_' can not be a reference"  if ref $attr_def->{$_};
        return "$error_start property '$_' can not be empty"  unless $attr_def->{$_};
        $self->{$_} = delete $attr_def->{$_};
    }
    if   (exists $attr_def->{'use'})     {$self->{'load'} = delete $attr_def->{'use'} }
    elsif(exists $attr_def->{'require'}) {$self->{'load'} = delete $attr_def->{'require'}; $self->{'require'} = 1; }
    else                                 {$self->{'load'} = $self->{'class'}}

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
sub class          {$_[0]->{'class'}}
sub build_code     {$_[0]->{'build'}}
sub is_lazy        {$_[0]->{'lazy'}}
sub load_package   {$_[0]->{'load'}}
sub require_package{$_[0]->{'require'}}

1;
__END__

wrapping attribute name => { help  => '',                 # short explaining text for better ~errormsg
                            class  => 'Kephra::...',      # class of attribute (can be any)
                  ?|          use  => 'Module qw/symbol/' # package you actually have to use/import, defaults to ~class
                  ?|      require  => 'Module'            # package you actually have to require , defaults to use
                             wrap  => [wrapper_name]|name # accessor methods
                   |  [lazy_]build => 'code'              # code snippets to run (lazily) create $attr object and bring it into init state

required 

     class : ~
     build : ~(code)             # create default value (reset)

optional

    getter : ~ // name
 get_scope : 'build' | 'access' | 'private' | 'public' // 'access'
   is_lazy : ?

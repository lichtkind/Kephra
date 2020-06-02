use v5.20;
use warnings;

package Kephra::Base::Class::Definition::Attribute::Wrapping;
our $VERSION = 1.0;

################################################################################
sub new {        # ~pkg %attr_def            --> ._ | ~errormsg
    my ($pkg, $attr_def) = (@_);
    return "need a property hash to create a wrapping attribute definition" unless ref $attr_def eq 'HASH';
    my $error_start = ("wrapping attribute $attr_def->{name}");
    my $self = {methods => [], auto => {}, lazy => 0};
    for (qw/name help class/) {
        return "$error_start lacks property '$_'" unless exists $attr_def->{$_};
        return "$error_start property '$_' can not be a reference"  if ref $attr_def->{$_};
        return "$error_start property '$_' can not be empty"  unless $attr_def->{$_};
        $self->{$_} = delete $attr_def->{$_};
    }
    return "method definition (property 'wrap') of $error_start has to be a method name or an array (reference) with method names" 
        if ref $attr_def->{'wrap'} and ref $attr_def->{'wrap'} ne 'ARRAY';
    $self->{'wrap'} = delete $attr_def->{'wrap'};

    $self->{'require'} = delete $attr_def->{'require'} if exists $attr_def->{'require'};

    if   (exists $attr_def->{'build'})     {$self->{'build'} = delete $attr_def->{'build'} }
    elsif(exists $attr_def->{'lazy_build'}){$self->{'build'} = delete $attr_def->{'lazy_build'}; $self->{'lazy'} = 1; }
    else {return "build code for $error_start is missing. Use property 'build' or 'lazy_build'." }

    for (keys %$attr_def){ return "$error_start has the illegal, malformed or effectless property '$_'"  }
    bless $self;
}
################################################################################
sub state   { $_[0] }
sub restate { bless shift }
################################################################################
sub get_kind  {'wrapping'}
sub get_help  {$_[0]->{'help'}}
sub get_type  { undef }
sub get_init  { undef }
sub get_build {$_[0]->{'build'}}
sub is_lazy   {$_[0]->{'lazy'}}
sub accessor_names  {@{ $_[0]->{'methods'}} }
sub auto_accessors  { undef }
sub get_dependency  { undef }
sub get_requirement { $_[0]->{'require'} // $_[0]->{'class'} }

1;
__END__

wrapping attribute name => { help  => '',                 # short explaining text for better ~errormsg
                            class  => 'Wx::...',          # class of attribute (can be any perl none KBOS class)
                ?          require => 'Module'            # only if requires different module than ~class
                            wrap   => [wrapper_name,]     # claim this to be implemented wrapper method as belonging to this attribute
                 |    build[_lazy] => ['code']|{name=>''} # code snippets to run (lazily) create $attr object

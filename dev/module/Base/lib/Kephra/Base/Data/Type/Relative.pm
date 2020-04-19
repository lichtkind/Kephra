use v5.20;
use warnings;

# data type checker that tage arguments, standards (here) + added by any package (owner)
# types can inherit from simple ones (KB::Data::Type), help is descrition, all error msg inside code

package Kephra::Base::Data::Type::Relative;
our $VERSION = 0.05;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Data::Type;
use Kephra::Base::Package;
use Exporter 'import';
our @EXPORT_OK = (qw/check_type known_type/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my %set ;        # storage for all active types
my @standard = ( # standard types - no package can delete them
  index => {code =>'return out of range if $_[0] >= @{$_[1]}', arguments =>[{name => 'array', type => 'ARRAY', default => []},], 
            help => 'valid index of array', parent => 'int_pos' },
  typed_array => {code => 'for my $vi (0..$#{$_[0]}){my $ret = $_[1]->($_[0][$vi]); return "array element $vi : $ret" if $ret}',
                  arguments =>[{name => 'type name', type =>'TYPE', default => 'str', eval => 'Kephra::Base::Data::Type::get_callback($_[1])'} ,],
                  help => 'array with typed elements', parent => 'ARRAY', shortcut => '@', },
  typed_hash  => {code => 'for my $vk (keys %{$_[0]}){my $ret = $_[1]->($_[0]{$vk}); return "hash value of key $vk : $ret" if $ret}',
                  arguments =>[{name => 'type name', type =>'TYPE', default => 'str', eval => 'Kephra::Base::Data::Type::get_callback($_[1])'} ,
                  help => 'hash with typed values', parent => 'HASH', shortcut => '%',],},
);
my %shortcut = ( '-' => 0, '>' => 0, '<' => 0, ',' => 0,);
while (@standard){
    my $error = add(shift @standard, shift @standard);
    die $error if $error;
}
################################################################################
for my $type (keys %set){
    die "relative type name $type contains none word character" unless $type =~ /^\w+$/;
    die "relative type name $type has same name as regular type" if Kephra::Base::Data::Type::is_known($type);
    if (exists $set{$type}{'default'}){
        #my $msg = check($type, $set{$type}{'default'});
        #die "default value of type $type : $set{$type}{default} misses requirement, $msg" if $msg;
    }
    die 'relative type shortcut '.$shortcut{ $set{$type}{'shortcut'} }.' is used twice'
    if exists $set{$type}{'shortcut'} and exists $shortcut{ $set{$type}{'shortcut'} };
    $shortcut{ $set{$type}{'shortcut'} } = $type if exists $set{$type}{'shortcut'};
}

################################################################################
sub add    {                                # name help cref parent? --> bool
    my ($type, $help, $code, $args, $default, $parent, $shortcut) = @_;
    return "type name: '$type' is already in use" if is_known($type);
    return "type name: '$type' contains none word character" unless $type =~ /^\w+$/;
    if (ref $help eq 'HASH'){
        $shortcut = $help->{'shortcut'} if exists $help->{'shortcut'};
        $default = $help->{'default'}  if exists $help->{'default'};
        $parent = $help->{'parent'}  if exists $help->{'parent'};
        $args = $help->{'arguments'} if exists $help->{'arguments'};
        $code = $help->{'code'}  if exists $help->{'code'};
        $help = exists $help->{'help'} ? $help->{'help'} : undef;
    }
    return 0 unless ref $args eq 'ARRAY' and @$args > 0; # need arg def
    for my $arg (@$args){
        #return 0 unless exists $arg->{'name'} and exists $arg->{'type'} and Kephra::Base::Data::Type::is_known($arg->{'type'});
    }
    return 0 if defined $parent and not Kephra::Base::Data::Type::is_known( $parent );
    return 0 if defined $shortcut and exists $shortcut{ $shortcut };

    my ($package, $file, $line) = caller();
    return 0 if not $package;               # only package (classes) can have types
    return 0 if defined $parent and $parent and not is_known($parent);
    $set{$type} = {package => $package, file => $file, code => $code, arg => $args};
    $set{$type}{'parent'}   = $parent if defined $parent;
    $set{$type}{'shortcut'} = $shortcut if defined $shortcut;
    $shortcut{ $shortcut } = $type if defined $shortcut;

    0;
}
sub delete {                              # name       -->  bool
    my ($name) = @_;
    return "type name $name in not in use" unless is_known($name);
    return "type $name can not be deleted (is standard)" if is_standard($name);
    my ($package, $file, $line) = caller();
    return "type $name  is owned by another package and can not be deleted" unless _owned($name, $package, $file);
    delete $shortcut{ $set{$name}{'shortcut'} } if exists $set{$name}{'shortcut'};
    delete $set{$name};
    return 0;
}
################################################################################
sub list_names     { keys %set }                    #            --> @~type
sub list_shortcuts { keys %shortcut }               #            --> @~shortcut
sub resolve_shortcut {                              # ~shortcut  -->  ~type
    $shortcut{$_[0]} if defined $shortcut{$_[0]}
}
################################################################################
sub is_known    { exists $set{$_[0]} ? 1 : 0 } 
sub is_standard {(exists $set{$_[0]} and not exists $set{$_[0]}{'file'}) ? 1 : 0 }
sub is_owned {
    my ($package, $sub, $file, $line) = Kephra::Base::Package::sub_caller();
    _owned($_[0], $package, $file);
}
sub _owned {
    my ($type, $package, $file) = @_;
    (exists $set{$type} and exists $set{$type}{'package'} and $set{$type}{'package'} eq $package
                        and exists $set{$type}{'file'} and $set{$type}{'file'} eq $file) ? 1 : 0
}
################################################################################
sub get_default_value { $set{$_[0]}{'default'} if exists $set{$_[0]} and exists $set{$_[0]}{'default'}}
sub get_argument_count { int @{$set{$_[0]}{'arg'}} if exists $set{$_[0]} }
sub get_argument_type  {
    my ($type, $index) = @_;
    return 0 unless is_known($type) and defined $index and $index < int @{$set{$type}{'arg'}} and $index >= 0;
    $set{$type}{'arg'}[$index]{'type'};
}
sub get_argument_label {
    my ($type, $index) = @_;
    return 0 unless is_known($type) and defined $index and $index < int @{$set{$type}{'arg'}} and $index >= 0;
    $set{$type}{'arg'}[$index]{'label'};
}



1;



__END__


    _resolve_dependencies($type);
    if (defined $default){
        if (check($type, $default)) {delete $set{$type}; return 0}
        else                        {$set{$type}{default} = $default}
    }


for my $type (keys %set){
    _resolve_dependencies($type);
    if (exists $set{$type}{default}){
        my $msg = check($type, $set{$type}{default});
        die "default value of type $type : $set{$type}{default} misses requirement: $msg" if $msg;
    }
}

sub _resolve_dependencies {
    my ($type) = @_;
    die "can not resolve type $type" unless defined $type and exists $set{$type};
    return unless exists $set{$type}{parent};
    my $parent = $set{$type}{parent};
    _resolve_dependencies($parent);
    $set{$type}{default} = $set{$parent}{default} if not defined $set{$type}{default};
    unshift @{$set{$type}{check}}, @{$set{$parent}{check}};
    delete $set{$type}{parent};
}
################################################################################

sub get_default_value { $set{$_[0]}{'default'} if exists $set{$_[0]} and exists $set{$_[0]}{'default'}}
sub get_checks     { $set{$_[0]}{'check'} if exists $set{$_[0]} }
sub get_callback {  # type                                 --> &callback
    my ($type) = @_;
    return unless exists $set{$type};
    return $set{$type}{'callback'} if exists $set{$type}{'callback'};
    my $c = get_checks($type);
    no warnings "all";
    my $l = @$c;
    $set{$type}{'callback'} = sub {
        my $val = shift;
        for (my $i = 0; $i < $l; $i+=2){return "$val needed to be of type $type, but failed test: $c->[$i]" unless $c->[$i+1]->($val)}'';
    }
}
################################################################################
sub check_type    {&check}
sub check         { # name val  --> errormsg|''
    my ($type, $value) = @_;
    my $callback = get_callback($type);
    return "no type named $type known" unless ref $callback;
    $callback->($value);
}
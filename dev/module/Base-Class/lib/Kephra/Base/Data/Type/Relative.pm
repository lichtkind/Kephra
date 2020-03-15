use v5.20;
use warnings;

package Kephra::Base::Data::Type::Relative;
our $VERSION = 0.01;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Data::Type;
use Kephra::Base::Package;
use Exporter 'import';
our @EXPORT_OK = (qw/check_type known_type/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my %set = (index => {code =>'return out of range if $_[0] >= @{$_[1]}', arguments =>[{label => 'array', type => 'ARRAY', default=>[]},], parent => 'int_pos' },
     typed_array => {code => 'for my $vi (0..$#{$_[0]}){my $ret = $check->($_[0][$vi]); return "array element $vi : $ret" if $ret}', parent => 'ARRAY', shortcut => '@',
                     arguments =>[{label => 'type name', type =>'TYPE', var => 'check', eval => 'Kephra::Base::Data::Type::get_callback($_[1])', default => 'str'} ,],},
     typed_hash  => {code => 'for my $vk (keys %{$_[0]}){my $ret = $check->($_[0]{$vk}); return "hash value of key $vk : $ret" if $ret}', parent => 'HASH', shortcut => '%',
                     arguments =>[{label => 'type name', type =>'TYPE', var => 'check', eval => 'Kephra::Base::Data::Type::get_callback($_[1])', default => 'str'} ,],},
);
my %shortcut = ( '-' => 0, '>' => 0, '<' => 0, ',' => 0,);
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
    my ($type, $code, $args, $default, $parent, $shortcut) = @_;
    return 0 if is_known($type);            # do not overwrite types
    return 0 unless $type =~ /^\w+$/;       # type name can only sontain word char
    if (ref $msg eq 'HASH'){               # name => {help =>'...', check => sub {},  parent => 'type'}
        $shortcut = $code->{'shortcut'} if exists $code->{'shortcut'};
        $default = $code->{'default'}  if exists $code->{'default'};
        $parent = $code->{'parent'}   if exists $code->{'parent'};
        $args = $code->{'arguments'} if exists $code->{'arguments'};
        $code = $code->{'code'}     if exists $code->{'code'};
    }
    return 0 unless defined $code;
    return 0 unless ref $args eq 'ARRAY' and @$args > 0; # need arg def
    for my $arg (@$args){
        return 0 unless exists $arg->{'label'} and exists $arg->{'type'} and Kephra::Base::Data::Type::is_known($arg->{'type'});
    }
    return 0 if defined $parent and not is_known($parent); 
    return 0 if defined $shortcut and exists $shortcut{ $shortcut };

    my ($package, $sub, $file, $line) = Kephra::Base::Package::sub_caller();
    return 0 if not $package;               # only package (classes) can have types
    return 0 if defined $parent and $parent and not is_known($parent);
    $set{$type} = {package => $package, file => $file, code => $code, arguments => $args};


    $shortcut{ $shortcut } = $type if defined $shortcut;

    1;
}

################################################################################
sub is_known    { is_relative($_[0]) or Kephra::Base::Data::Type::is_known($_[0]) } 
sub is_relative { exists $set{$_[0]} ? 1 : 0 } 
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

sub delete {                              # name       -->  bool
    my ($name) = @_;
    return 0 unless is_known($name);      # can only delete existing types
    return 0 if is_standard($name);       # cant delete std types
    my ($package, $sub, $file, $line) = Kephra::Base::Package::sub_caller();
    return 0 unless _owned($name, $package, $file); # only creator can delete type
    delete $set{$name};
    return 1;
}

sub list_names  { keys %set }                  #            --> [name]
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
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

my %set = (index => {msg => 'in range', code =>'$_[0] < @{$_[1]}', arguments =>[{msg => 'array', type => 'ARRAY', default=>[]},], parent => 'int+' },
     typed_array => {code => 'for my $vi (0..$#{$_[0]}){my $ret = $check->($_[0]); return "array element $vi $ret" if $ret}', parent => 'ARRAY',
                     arguments =>[{msg => 'type name', type =>'TYPE', var => 'check', eval => 'Kephra::Base::Data::Type::get_callback($_[1])', default => 'str'} ,],}
);
my %shortcut = ('-' => 0);
################################################################################
for my $type (keys %set){
    if (exists $set{$type}{'default'}){
        my $msg = check($type, $set{$type}{'default'});
        die "default value of type $type : $set{$type}{default} misses requirement, $msg" if $msg;
    }
    $shortcut{ $set{$type}{'shortcut'} } = $type if exists $set{$type}{'shortcut'};
}

1;

__END__

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

sub add    {                                # name help cref parent? --> bool
    my ($type, $msg, $code, $arguments, $default, $parent, $shortcut) = @_;
    return 0 if is_known($type);            # do not overwrite types
    if (ref $help eq 'HASH'){               # name => {help =>'...', check => sub {},  parent => 'type'}
        return 0 unless exists $help->{'help'} and exists $help->{'check'};
        $help = $help->{'help'};
        $default = $help->{'default'};
        $parent = $help->{'parent'};
        $check = $help->{'check'};
        $help  = $help->{'help'};
    }
    return 0 unless ref $check eq 'CODE'; # need a checker
    my ($package, $sub, $file, $line) = Kephra::Base::Package::sub_caller();
    return 0 if not $package;               # only package (classes) can have types
    return 0 if defined $parent and $parent and not is_known($parent);
    $set{$type} = {package => $package, file => $file, check => [$help, $check],  parent => $parent};
    _resolve_dependencies($type);
    if (defined $default){
        if (check($type, $default)) {delete $set{$type}; return 0}
        else                        {$set{$type}{default} = $default}
    }
    1;
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
sub is_known    { exists $set{$_[0]} ? 1 : 0 } # name       -->  bool
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
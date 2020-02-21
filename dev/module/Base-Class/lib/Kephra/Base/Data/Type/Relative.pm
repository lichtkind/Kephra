use v5.16;
use warnings;

package Kephra::Base::Data::Type::Relative;
our $VERSION = 0.08;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Data::Type;
use Kephra::Base::Package;
use Exporter 'import';
our @EXPORT_OK = (qw/check_type guess_type known_type/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my %set = (bool  => {check => ['boolean',          sub{$_[0] eq 0 or $_[0] eq 1}],parent => 'value', default=>0},
           num   => {check => ['number',           sub{looks_like_number($_[0])}],parent => 'value', default=>0},
          'num+' => {check => ['positive number',  sub{$_[0]>=0}],                parent => 'num', },
           int   => {check => ['integer',          sub{int $_[0] == $_[0]}],      parent => 'num', },
          'int+' => {check => ['positive integer', sub{$_[0]>=0}],                parent => 'int', },
          'int++'=> {check => ['strictly positive integer',sub{$_[0]> 0}],        parent => 'int',   default=>1},
          'str'  => {check => [],                                                 parent => 'value'},
          'str+' => {check => ['none empty string',sub{$_[0] or ~$_[0]}],         parent => 'str',   default=> ' '},
          'str+lc'=>{check => ['lower case string',sub{lc $_[0] eq $_[0]}],       parent => 'str+'},
          'str+uc'=>{check => ['upper case string',sub{uc $_[0] eq $_[0]}],       parent => 'str+'},
          'str+wc'=>{check => ['word case string', sub{ucfirst $_[0] eq $_[0]}],  parent => 'str+'},
          'value' =>{check => ['not a reference',  sub{not ref $_[0]}],                              default=>''},

          'obj'  => {check => ['object',           sub{blessed($_[0])}]},
          'any'  => {check => ['any value',        sub{1}]},

          'CODE' => {check => ['code reference',   sub{ref $_[0] eq 'CODE'}]},
          'ARRAY'=> {check => ['array reference',  sub{ref $_[0] eq 'ARRAY'}]},
          'HASH' => {check => ['hash reference',   sub{ref $_[0] eq 'HASH'}]},
          'ARGS' => {check => ['array or hash ref',sub{ref $_[0] eq 'ARRAY' or ref $_[0] eq 'HASH'}]},
);

################################################################################

sub add    {                                # name help cref parent? --> bool
    my ($type, $help, $check, $default, $parent) = @_;
    return 0 if is_known($type);            # do not overwrite types
    if (ref $help eq 'HASH'){               # name => {help =>'...', check => sub {},  parent => 'type'}
        return 0 unless exists $help->{'help'};
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

sub guess_type   {&guess}
sub guess        { # val          --> [name]
    my ($value) = @_;
    return '' unless defined $value;
    my @found = ();
    for my $name(list_names()){
        push @found, $name unless check($name, $value);
    }
    @found;
}
################################################################################

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

for my $type (keys %set){
    _resolve_dependencies($type);
    if (exists $set{$type}{default}){
        my $msg = check($type, $set{$type}{default});
        die "default value of type $type : $set{$type}{default} misses requirement: $msg" if $msg;
    }
}

################################################################################
1;
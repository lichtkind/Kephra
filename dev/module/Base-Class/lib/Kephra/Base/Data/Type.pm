use v5.20;
use warnings;

# mechanism to check data types, standards (here) + added by any package (owner)
# types do inherit from each other, each child adds one check (code) and an according help message

package Kephra::Base::Data::Type;
our $VERSION = 0.07;
use Scalar::Util qw/blessed looks_like_number/;
use Kephra::Base::Package;
use Exporter 'import';
our @EXPORT_OK = (qw/check_type guess_type known_type/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my %set ;        # storage for all active types
my @standard = ( # standard types - no package can delete them
  'value'  => {help=> 'not a reference',     code=> 'not ref $_[0]',                               default=> ''                },
  'bool'   => {help=> '0 or 1',              code=> '$_[0] eq 0 or $_[0] eq 1', parent=> 'value',  default=> 0,   shortcut=> '?'},
  'num'    => {help=> 'number',              code=> 'looks_like_number($_[0])', parent=> 'value',  default=> 0,   shortcut=> '+'},
  'num_pos'=> {help=> 'greater equal zero',  code=> '$_[0]>=0',                 parent=> 'num', },
  'int'    => {help=> 'integer',             code=> 'int $_[0] == $_[0]',       parent=> 'num', },
  'int_pos'=> {help=> 'positive integer',    code=> '$_[0]>=0',                 parent=> 'int', },
  'int_spos'=>{help=> 'strictly positive',   code=> '$_[0] > 0',                parent=> 'int',    default=> 1},
  'str'    => {                                                                 parent=> 'value'},                                 # pure rename
  'str_ne' => {help=> 'none empty value',    code=> '$_[0] or ~$_[0]',          parent=> 'str',    default=> ' ', shortcut=> '~'}, # check it
  'str_lc' => {help=> 'lower case character',code=> 'lc $_[0] eq $_[0]',        parent=> 'str_ne'},
  'str_uc' => {help=> 'upper case character',code=> 'uc $_[0] eq $_[0]',        parent=> 'str_ne'},
  'str_wc' => {help=> 'word case character', code=> 'ucfirst $_[0] eq $_[0]',   parent=> 'str_ne'},
  'name'   => {help=> 'word character (alphanum+_)', code=> '$_[0] =~ /^\w+$/', parent=> 'value',  default=> 'name'},

  'TYPE'   => {help=> 'type name',           code=> 'is_known $_[0]',           parent=> 'name',   default=> 'str_ne'},
  'CODE'   => {help=> 'code reference',      code=> q/ref $_[0] eq 'CODE'/,                                       shortcut=> '&'},
  'ARRAY'  => {help=> 'array reference',     code=> q/ref $_[0] eq 'ARRAY'/,                                      shortcut=> '@'},
  'HASH'   => {help=> 'hash reference',      code=> q/ref $_[0] eq 'HASH'/,                                       shortcut=> '%'},
  'ARGS'   => {help=> 'array or hash ref',   code=> q/ref $_[0] eq 'ARRAY' or ref $_[0] eq 'HASH'/},
  'REF'    => {help=> 'reference',           code=> 'ref $_[0]'},
  'OBJ'    => {help=> 'blessed object',      code=> 'blessed($_[0])'},
  'DEF'    => {help=> 'defined value',       code=> 'defined $_[0]'},
  'ANY'    => {help=> 'any data',            code=> 1},
);
my %shortcut = ( '-' => 0, '>' => 0, '<' => 0, ',' => 0,); #shortcut names 
while (@standard){
    my $error = add(shift @standard, shift @standard);
    die $error if $error;
}
################################################################################
sub add    {                                # name help cref parent? --> bool
    my ($type, $help, $code, $default, $parent, $shortcut) = @_;
    return "type name: '$type' is already in use" if is_known($type);
    return "type name: '$type' contains none word character" unless $type =~ /^\w+$/;
    if (ref $help eq 'HASH'){
        $shortcut = $help->{'shortcut'} if exists $help->{'shortcut'};
        $default = $help->{'default'}  if exists $help->{'default'};
        $parent = $help->{'parent'}  if exists $help->{'parent'};
        $code  = $help->{'code'}  if exists $help->{'code'};
        $help = exists $help->{'help'} ? $help->{'help'} : undef;
    }
    return "type name: '$type' has to have help and code or parent" if defined $code xor defined $help or (not defined $code and not defined $parent);
    return "parent type: '$parent' of '$type' is unknown" if defined $parent and not is_known( $parent );
    return "type shortcut: '$shortcut' is already used" if defined $shortcut and exists $shortcut{ $shortcut };
    my ($package, $file, $line) = caller();
    return "a type has to be created in a named package inside a file" unless defined $file and $package ne 'main';

    $set{$type} = {check => [], };
    push   @{$set{$type}{'check'}}, $help, $code if defined $code;
    if (defined $parent){
        unshift @{$set{$type}{'check'}}, @{$set{$parent}{'check'}};
        $set{$type}{'default'} = $set{$parent}{'default'} if exists $set{$parent}{'default'};
        $set{$type}{'parent'} = $parent;
    }
    if ($package ne __PACKAGE__){
        $set{$type}{'file'}    = $file;
        $set{$type}{'package'} = $package;
    }
    if (defined $default){
        if (check($type, $default)) {delete $set{$type}; return "default value $default does not pass checker of type $type"}
        else                        {$set{$type}{'default'} = $default}
    }
    if (defined $shortcut){
        $set{$type}{'shortcut'} = $shortcut;
        $shortcut{ $shortcut } = $type;
    }
    0;
}
sub delete {                              # name       -->  bool
    my ($name) = @_;
    return 0 unless is_known($name);      # can only delete existing types
    return 0 if is_standard($name);       # can't delete std types
    my ($package, $sub, $file, $line) = Kephra::Base::Package::sub_caller();
    return 0 unless _owned($name, $package, $file); # only creator can delete type
    delete $shortcut{ $set{$name}{'shortcut'} } if exists $set{$name}{'shortcut'};
    delete $set{$name};
    return 1;
}
################################################################################
sub list_names     { keys %set }                    #            --> @~type
sub list_shortcuts { keys %shortcut }               #            --> @~shortcut
sub resolve_shortcut {                              # ~shortcut  -->  ~type
    $shortcut{$_[0]} if defined $shortcut{$_[0]}
}
################################################################################
sub known_type  { &is_known }
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
    my $callback = 'sub { ';
    for (my $i = 0; $i < $l; $i+=2){
        $callback .= 'return "value $_[0]'." needed to be of type $type, but failed test: $c->[$i]\" unless $c->[$i+1];";
    }
    $callback = eval $callback.'return \'\'}';
    $set{$type}{'callback'} = $@ ? $@ : $callback
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
1;

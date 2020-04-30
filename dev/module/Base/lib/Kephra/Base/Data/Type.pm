use v5.20;
use warnings;

# mechanism to check data types, standards (here) + added by any package (owner)
# types do inherit from each other, each child adds one check (code) and an according help message

package Kephra::Base::Data::Type;
our $VERSION = 0.1;
use Kephra::Base::Package;
use Kephra::Base::Data::Type::Simple;
use Kephra::Base::Data::Type::Parametric;
use Exporter 'import';
our @EXPORT_OK = (qw/check_type guess_type known_type/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
my (%set, %shortcut);        # storage for all active types
my %forbidden_shortcuts = ('{' => 0, '}' => 0, '(' => 0, ')' => 0, '<' => 0, '>' => 0, ',' => 0);
##############################################################################
sub init {
    return if %set;
    my %simple_shortcut = ( %forbidden_shortcuts, 
    '~' => 'str', '?' => 'bool', '+' => 'num', '§' => 'int', '@' => 'array_ref', '%' => 'hash_ref', '&' => 'code_ref', '\' => 'any_ref',  );
    my %param_shortcut = ( %forbidden_shortcuts, '@' => 'typed_array', '%' => 'typed_hash');
    my @standard_simple_types = ( # standard simple types - no package can delete them
    {name => 'value',     help=> 'defined value',        code=> 'defined $value',                                  default=> '' },
    {name => 'no_ref',    help=> 'not a reference',      code=> 'not ref $value',             parent=> 'value',                },
    {name => 'bool',      help=> '0 or 1',               code=> '$value eq 0 or $value eq 1', parent=> 'no_ref',   default=> 0  },
    {name => 'num',       help=> 'number',               code=> 'looks_like_number($value)',  parent=> 'no_ref',   default=> 0  },
    {name => 'num_pos',   help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'num'                   },
    {name => 'num_spos',  help=> 'greater equal zero',   code=> '$value > 0',                 parent=> 'num',      default=> 1  },
    {name => 'int',       help=> 'number',               code=> 'int($value) eq $value',      parent=> 'no_ref',   default=> 0  },
    {name => 'int_pos',   help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'int'                   },
    {name => 'int_spos',  help=> 'strictly positive',    code=> '$value > 0',                 parent=> 'int',      default=> 1  },
    {name => 'str',                                                                           parent=> 'no_ref',               },
    {name => 'str_ne',    help=> 'none empty string',    code=> '$value or ~$value',          parent=> 'no_ref',   default=> ' '},
    {name => 'str_lc',    help=> 'lower case string',    code=> 'lc $value eq $value',        parent=> 'str_ne',   default=> 'a'},
    {name => 'str_uc',    help=> 'upper case string',    code=> 'uc $value eq $value',        parent=> 'str_ne',   default=> 'A'},
    {name => 'word',      help=> 'word character',       code=> '$value =~ /^\w+$/',          parent=> 'str_ne',   default=> 'a'},
    {name => 'arg_name',  help=> 'argument name',        code=> 'lc $value eq $value',        parent=> 'word',     default=> 'a'},
    {name => 'type',      help=> 'simple type name',     code=> 'ref Kephra::Base::Data::Type::get($value)',                          
                                                                                              parent=> 'arg_name', default=> 'noref'},
    {name => 'scalar_ref',help=> 'array reference',      code=> q/ref $value eq 'ARRAY'/,                          default=> [] },
    {name => 'array_ref', help=> 'array reference',      code=> q/ref $value eq 'ARRAY'/,                          default=> [] },
    {name => 'hash_ref',  help=> 'hash reference',       code=> q/ref $value eq 'HASH'/,                           default=> {} },
    {name => 'code_ref',  help=> 'code reference',       code=> q/ref $value eq 'CODE'/,                           default=> sub {} },
    {name => 'type_ref',  help=> 'code reference',       code=> q/ref $value eq 'Kephra::Base::Data::Type::Simple'/,default=> Kephra::Base::Data::Type::Simple->new('t','test',3,undef,4) },
    {name => 'object',    help=> 'object reference',     code=> q/blessed($value)/,                                default=> bless {} },
#   {name => 'kb_object', help=> 'kephra base object',   code=> q/blessed($value)/,                                default=> bless {} },
    {name => 'any_ref',   help=> 'reference of any sort',code=> q/ref $value/,                                     default=> [] }, 
    ); #    'ARGS'   => 'ARRAY | HASH }, # ANY
    my @standard_param_types = ( # standard simple types - no package can delete them
    {name => 't_ref',     help=> 'reference of given type',  code=> 'return "value $value is not a $param reference" if ref $value ne $param',  parent=> 'value',     default=> [] },
                                                                                                            pameter => {   name => 'refname',     type=> 'str',       default=> 'ARRAY'}, 
    {name => 'index',     help=> 'valid index of array',     code=> 'return "value $value is out of range" if $value >= @$param',               parent=> 'int_pos',   default=>  0 },
                                                                                                            pameter => {   name => 'array',       type=> 'array_ref', default=> [1]    }, 
    {name => 't_array',   help=> 'array with typed elements',                                                                                   parent=> 'array_ref', default=> [1],
                                                             code=> 'for my $i(0..$#$value){my $error = $parame->check($value->[$i]); return "aray element $i $error" if $error}',
                                                                                                            pameter => {   name => 'element_type',type=> 'type_ref',               },  }, 
    );
    while (@standard){
        my $error = add(shift @standard, shift @standard);
        die $error if $error;
    }
}
sub state {
    my %state = ();
    for my $k (keys %set){
        @{$state{$k}{'check'}} = @{$set{$k}{'check'}};
        $state{$k}{'default'}  = $set{$k}{'default'}  if exists $set{$k}{'default'};
        $state{$k}{'file'}     = $set{$k}{'file'}     if exists $set{$k}{'file'};
        $state{$k}{'package'}  = $set{$k}{'package'}  if exists $set{$k}{'package'};
        $state{$k}{'shortcut'} = $set{$k}{'shortcut'} if exists $set{$k}{'shortcut'};
    }
    \%state;
}
sub restate {
    my ($state) = @_;
    return if %set or ref $state ne 'HASH';
    for my $k (keys %$state){
        next unless ref $state->{$k} eq 'HASH' and ref $state->{$k}{'check'} eq 'ARRAY';
        $set{$k} = $state->{$k};
        $shortcut{ $state->{$k}{'shortcut'} } = $k if exists $state->{$k}{'shortcut'};
    }
}
################################################################################
sub add    { # ~type ~help ~check - $default ~parent ~shortcut --> ~error
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
sub delete {  # ~type       -->  ~error
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
__END__
my $Ttyped_array = para_type('Tarray', 'array with typed elements', {name => 'type', type => $Tval, default => 'ARRAY'}, 'return "value $value is not a $param reference" if ref ne $param', $Tarray, [1]);
    return "type name: '$name' is empty or contains none word character" unless $name and $name !~ /\W/;
    return "shortcut of $name: '$shortcut' contains word character" if defined $shortcut and $shortcut !~ /\w/;

__END__

shortcuts

@ array_ref
% hash_ref
\ any_ref
$ value
~ string
? bool
+ number
§ integer
^
# 
'
"
! none KBOS object
. KBOS object
/
| type name
-
=
: arg name
;



not allowes _ , ( ) < >  { }


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
set
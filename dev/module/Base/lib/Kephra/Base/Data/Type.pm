use v5.20;
use warnings;
use utf8;

# store of standard types, owners (packages can add and remove types)

package Kephra::Base::Data::Type;
our $VERSION = 0.5;
use Kephra::Base::Package;
use Kephra::Base::Data::Type::Simple;
use Kephra::Base::Data::Type::Parametric;
use Exporter 'import';
our @EXPORT_OK = (qw/check_type guess_type is_type_known/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
my (%simple_type, %param_type, %simple_shortcut, %param_shortcut);        # storage for all active types
my %forbidden_shortcut = ('{' => 1, '}' => 1, '(' => 1, ')' => 1, '<' => 1, '>' => 1, ',' => 1);
##############################################################################
sub init {
    return if %simple_type;
    my %simple_sc = ( 'str' => '~', 'bool' => '?', 'num' => '+', 'int' => '-', # ^ # ' " ! . / - = §;
                      'value' => '$', 'array_ref' => '@', 'hash_ref' => '%', 'code_ref' => '&', 'any_ref' => '\\', 'type' => '|', 'arg_name' => ':');
    my %param_sc = ( 'typed_array' => '@', 'typed_hash' => '%');
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
    {name => 'type_name', help=> 'simple type name',     code=> 'ref Kephra::Base::Data::Type::get($value)',                          
                                                                                              parent=> 'arg_name', default=> 'no_ref'},
    {name => 'scalar_ref',help=> 'array reference',      code=> q/ref $value eq 'SCALAR'/,                         default=> \1 },
    {name => 'array_ref', help=> 'array reference',      code=> q/ref $value eq 'ARRAY'/,                          default=> [] },
    {name => 'hash_ref',  help=> 'hash reference',       code=> q/ref $value eq 'HASH'/,                           default=> {} },
    {name => 'code_ref',  help=> 'code reference',       code=> q/ref $value eq 'CODE'/,                           default=> sub {} },
    {name => 'type',      help=> 'code reference',       code=> q/ref $value eq 'Kephra::Base::Data::Type::Simple'/,default=> Kephra::Base::Data::Type::Simple->new('t','test',3,undef,4) },
    {name => 'object',    help=> 'object reference',     code=> q/blessed($value)/,                                default=> bless {} },
#   {name => 'kb_object', help=> 'kephra base object',   code=> q/blessed($value)/,                                default=> bless {} },
    {name => 'any_ref',   help=> 'reference of any sort',code=> q/ref $value/,                                     default=> [] }, 
    );
    my @standard_param_types = ( # standard simple types - no package can delete them
    {name => 'typed_ref', help=> 'reference of given type',  code=> 'return "value $value is not a $param reference" if ref $value ne $param',  parent=> 'value',     default=> [], 
                                                                                                            parameter => {   name => 'refname',     type=> 'str',       default=> 'ARRAY'}, },
    {name => 'index',     help=> 'valid index of array',     code=> 'return "value $value is out of range" if $value >= @$param',               parent=> 'int_pos',   default=>  0, 
                                                                                                            parameter => {   name => 'array',       type=> 'array_ref', default=> [1]    }, },
    {name => 'typed_array',help=> 'array with typed elements',                                                                                  parent=> 'array_ref', default=> [1],
                                                             code=> 'for my $i(0..$#$value){my $error = $param->check($value->[$i]); return "aray element $i $error" if $error}',
                                                                                                            parameter => {   name => 'element_type',type=> 'type',                 },  }, 
    );
    for my $typedef (@standard_simple_types){
        my $type = create_simple($typedef);
        die $type unless ref $type;
        my $error = add($type, $simple_sc{ $type->get_name });
        die 'standard simple type definition error - '.$error if $error;
    }
    for my $typedef (@standard_param_types){
        my $type = create_param($typedef);
        die $type unless ref $type;
        my $error = add($type, $param_sc{ $type->get_name });
        die 'standard parametric type definition error - '.$error if $error;
    }
}
sub state {
    my %state = ();
}
sub restate {
    my ($state) = @_;
}
################################################################################
sub create_simple     {  # ~name ~help ~code - .parent|~parent  $default     --> .type | ~errormsg
    my ($name, $help, $code, $parent, $default) = Kephra::Base::Data::Type::Simple::_unhash_arg_(@_);
    my $name_error = _validate_name_($name);
    return $name_error if $name_error;
    if (defined $parent){
        $parent = get($parent) if ref $parent ne 'Kephra::Base::Data::Type::Simple';
        return "fourth or named argument 'parent' of type '$name' has to be a name of a standard type or a simple type object"
            if ref $parent ne 'Kephra::Base::Data::Type::Simple';
    }
    Kephra::Base::Data::Type::Simple->new($name, $help, $code, $parent, $default);
}                       #             %{.type|~type - ~name $default }
sub create_param      { # ~name ~help %parameter ~code .parent|~parent - $default --> .ptype | ~errormsg
    my ($name, $help, $parameter, $code, $parent, $default) = Kephra::Base::Data::Type::Parametric::_unhash_arg_(@_);
    my $name_error = _validate_name_($name);
    return $name_error if $name_error;
    return "third or named argument 'parameter' of type '$name' has to be a hash reference with the key 'type'" if ref $parameter ne 'HASH' or not exists $parameter->{'type'};
    $parameter->{'type'} = get( $parameter->{'type'} ) if ref $parameter->{'type'} ne 'Kephra::Base::Data::Type::Simple';
    return "'parameter' 'type' definition has to be a name of a standard type or a simple type object" if ref $parameter->{'type'} ne 'Kephra::Base::Data::Type::Simple';
    $parent = get($parent) if ref $parent ne 'Kephra::Base::Data::Type::Simple';
    return "fifth or named argument 'parent' has to be a name of a standard type or a simple type object" if ref $parent ne 'Kephra::Base::Data::Type::Simple';
    Kephra::Base::Data::Type::Parametric->new($name, $help, $parameter, $code, $parent, $default);
}
################################################################################
sub _validate_name_ {
    return "type name is not defined" unless defined $_[0];
    return "type name $_[0] contains none id character" if  $_[0] !~ /[a-zA-Z0-9_]/;
    return "type name $_[0] contains upper chase character" if  lc $_[0] ne $_[0];
    return "type name $_[0] is too long" if  length $_[0] > 12;
    return "type name $_[0] is not long enough" if  length $_[0] < 3;
    0;
}
sub _validate_shortcut_ {
    return "type shortcut name is not defined" unless defined $_[0];
    return "type shortcut $_[0] contains id character" if  $_[0] =~ /[a-zA-Z0-9_]/;
    return "type shortcut $_[0] is too long" if length $_[0] > 1;
    return "type shortcut $_[0] is not allowed" if exists $forbidden_shortcut{$_[0]};
    0;
}

sub add    {                                   # ~[p]type ~shortcut          --> ~errormsg
    my ($type, $shortcut) = @_;
    return "$type is not a type object and can not be added to the standard" 
        if ref $type ne 'Kephra::Base::Data::Type::Simple' and ref $type ne 'Kephra::Base::Data::Type::Parametric';
    if (defined $shortcut){
        my $shortcut_error = _validate_shortcut_( $shortcut );
        return $shortcut_error if $shortcut_error;
    }
    my $type_name = $type->get_name;
    my $name_error = _validate_name_( $type_name );
    return $name_error if $name_error;
    my ($package, $file, $line) = caller();
    my $def = {object => $type, package => $package , file => $file };
    if (ref $type eq 'Kephra::Base::Data::Type::Parametric'){
        my $param_name = $type->get_parameter->get_name;
        my $name_error = _validate_name_( $type->get_parameter->get_name );
        return "type $type_name parameter: $name_error" if $name_error;
        return "type name $type_name with parameter $param_name is already in use" if exists $param_type{$type_name}{$param_name};
        if (defined $shortcut){
            return "parametric type shortcut $shortcut is already in use" if exists $param_shortcut{$shortcut};
            $param_shortcut{$shortcut} = $type_name;
            $def->{'shortcut'} = $shortcut;
        } 
        $param_type{$type_name}{$param_name} = $def;
    } else {
        return "simple type name $type_name is already in use" if exists $simple_type{$type_name};
        if (defined $shortcut){
            return "simple type shortcut $shortcut is already in use" if exists $simple_shortcut{$shortcut};
            $simple_shortcut{$shortcut} = $type_name;
            $def->{'shortcut'} = $shortcut;
        } 
        $simple_type{$type_name} = $def;
    }
    0;
}
sub remove {                                   # ~type - ~param              --> ~errormsg
    my ($type_name, $param_name) = @_;
    my $def = _get_(@_);
    return "type $type_name is unknown and can not be removed from standard" unless $def;
    my ($package, $file, $line) = caller();
    return "type $type_name is not owned by caller " unless $def->{'package'} eq $package and $def->{'file'} eq $file ;
    if (defined $param_name) { delete $param_type{$type_name}{$param_name} }
    else                     { delete $simple_type{$type_name} }
    $def->{'object'};
}
sub _get_ {
    my ($type_name, $param_name) = @_;
    return unless defined $type_name;
    if (defined $param_name) {
        $param_type{$type_name}{$param_name} if exists $param_type{$type_name} and exists $param_type{$type_name}{$param_name};
    } else {
        $simple_type{$type_name}             if exists $simple_type{$type_name};
    }
}
sub get {                                      # ~type - ~param ~uni         --> ~errormsg
    my ($tdef) = _get_(@_);
    ref $tdef ? $tdef->{'object'} : 0;
}
sub get_shortcut {                             # ~type - ~param ~uni         --> ~errormsg
    my ($tdef) = _get_(@_);
    ref $tdef ? $tdef->{'shortcut'} : 0;
}
sub list_names        {                        # - ~kind ~pname              --> @~type|@~ptype|@~param
    my ($kind, $type_name) = @_;
    if (defined $kind and index($kind, 'param') > -1) {
        if (defined $type_name){
            keys %{$param_type{$type_name}} if exists $param_type{$type_name}
        } else { keys %param_type }
    } else { keys %simple_type }
}
sub list_shortcuts    {                        #                             --> @~shortcut
    my ($kind) = @_;
    (defined $kind and index($kind, 'param') > -1) ? keys( %param_shortcut ) : keys( %simple_shortcut );
}
sub resolve_shortcut  {                        # ~shortcut - ~param          -->  ~type
    my ($shortcut, $kind) = @_;
    (defined $kind and index($kind, 'param') > -1) ? $param_shortcut{$shortcut} : $simple_shortcut{$shortcut}
}
################################################################################
sub is_type_known { &is_known }
sub is_known     { ref _get_(@_) ne '' }       # ~type - ~param              -->  ?
sub is_standard  {                             # ~type - ~param              -->  ?
    my ($tdef) = _get_(@_);
    return unless ref $tdef;
    $tdef->{'file'} eq __FILE__ and $tdef->{'package'} eq __PACKAGE__;
}
sub is_owned {
    my ($tdef) = _get_(@_);
    return unless ref $tdef;
    my ($package, $file, $line) = caller();
    $tdef->{'file'} eq $file and $tdef->{'package'} eq $package;
}
################################################################################
sub check_type    {&check_simple}
sub check_simple  {                              # ~name $val                --> errormsg
    my ($type_name, $value) = @_;
    my $type = get( $type_name );
    return "no type named $type_name known in the standard" unless ref $type;
    $type->check($value);
}
sub check_param  {                              # ~name $val                --> errormsg
    my ($type_name, $param_name, $value, $param_value) = @_;
    my $type = get( $type_name, $param_name );
    return "no type $type_name with parameter $param_name is known in the standard" unless ref $type;
    $type->check($value, $param_value);
}
sub guess_type   {&guess}
sub guess        {                                         # $val            --> @name
    my ($value) = @_;
    my @name;
    for my $name (list_names()) {push @name, $name unless check($name, $value)}
    @name;
}
################################################################################
1;

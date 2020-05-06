use v5.20;
use warnings;
use utf8;

# store of standard types, owners (packages can add and remove types)

package Kephra::Base::Data::Type::Standard;
our $VERSION = 1.3;
use Kephra::Base::Data::Type::Simple;
use Kephra::Base::Data::Type::Parametric;
use Exporter 'import';
our @EXPORT_OK = (qw/new_type check_type guess_type is_type_known/);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
my (%simple_type, %param_type, %name_by_shortcut, %shortcut_by_name);   # storage for all active types
my %forbidden_shortcut = ('{' => 1, '}' => 1, '(' => 1, ')' => 1, '<' => 1, '>' => 1, ',' => 1, '-' => 1);
my $stclass = 'Kephra::Base::Data::Type::Simple';
##############################################################################
sub init {
    return if (caller)[0] ne 'Kephra::Base::Data::Type';
    %simple_type = %param_type = %name_by_shortcut = %shortcut_by_name = ();
    my %simple_sc = ( str => '~', bool => '?', num => '+', int => '#', pos_int => '=',#  ^ ' " ! . /  §;
                      value => '$', array_ref => '@', hash_ref => '%', code_ref => '&', any_ref => '\\', type => '|', arg_name => ':', object => '!');
    my %param_sc = ( typed_array => '@', typed_hash => '%');
    my @standard_simple_types = ( # no package can delete them
    {name => 'any',       help=> 'anything',             code=> '1',                                                default=> '' },
    {name => 'value',     help=> 'defined value',        code=> 'defined $value',                                   default=> '' },
    {name => 'no_ref',    help=> 'not a reference',      code=> 'not ref $value',             parent=> 'value',                  },
    {name => 'bool',      help=> '0 or 1',               code=> '$value eq 0 or $value eq 1', parent=> 'no_ref',    default=> 0  },
    {name => 'num',       help=> 'number',               code=> 'looks_like_number($value)',  parent=> 'no_ref',    default=> 0  },
    {name => 'num_pos',   help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'num'                     },
    {name => 'num_spos',  help=> 'greater equal zero',   code=> '$value > 0',                 parent=> 'num',       default=> 1  },
    {name => 'int',       help=> 'number',               code=> 'int($value) eq $value',      parent=> 'no_ref',    default=> 0  },
    {name => 'int_pos',   help=> 'greater equal zero',   code=> '$value >= 0',                parent=> 'int'                     },
    {name => 'int_spos',  help=> 'strictly positive',    code=> '$value > 0',                 parent=> 'int',       default=> 1  },
    {name => 'str',                                                                           parent=> 'no_ref',                 },
    {name => 'str_ne',    help=> 'none empty string',    code=> '$value or ~$value',          parent=> 'no_ref',    default=> ' '},
    {name => 'str_lc',    help=> 'lower case string',    code=> 'lc $value eq $value',        parent=> 'str_ne',    default=> 'a'},
    {name => 'str_uc',    help=> 'upper case string',    code=> 'uc $value eq $value',        parent=> 'str_ne',    default=> 'A'},
    {name => 'word',      help=> 'word character',       code=> '$value =~ /^\w+$/',          parent=> 'str_ne',    default=> 'a'},
    {name => 'arg_name',  help=> 'argument name',        code=> 'lc $value eq $value',        parent=> 'word',      default=> 'a'},
    {name => 'type_name', help=> 'simple type name',     code=> 'ref Kephra::Base::Data::Type::Standard::get($value)',                          
                                                                                              parent=> 'arg_name',  default=> 'no_ref'},
    {name => 'scalar_ref',help=> 'array reference',      code=> q/ref $value eq 'SCALAR'/,                          default=> \1  },
    {name => 'array_ref', help=> 'array reference',      code=> q/ref $value eq 'ARRAY'/,                           default=> []   },
    {name => 'hash_ref',  help=> 'hash reference',       code=> q/ref $value eq 'HASH'/,                            default=> {}    },
    {name => 'code_ref',  help=> 'code reference',       code=> q/ref $value eq 'CODE'/,                            default=> sub {} },
    {name => 'type',      help=> 'code reference',       code=> q/ref $value eq 'Kephra::Base::Data::Type::Simple'/,default=> Kephra::Base::Data::Type::Simple->new('t','test',3,undef,4) },
    {name => 'object',    help=> 'object reference',     code=> q/blessed($value)/,                                 default=> bless {} },
#   {name => 'kb_object', help=> 'kephra base object',   code=> q/blessed($value)/,                                 default=> bless {} },
    {name => 'any_ref',   help=> 'reference of any sort',code=> q/ref $value/,                                      default=> [] }, 
    );
    my @standard_param_types = ( # standard simple types - no package can delete them
    {name => 'typed_ref', help=> 'reference of given type',  code=> 'return "value $value is not a $param reference" if ref $value ne $param',  parent=> 'value',     default=> [], 
                                                                                                          parameter => {   name => 'refname',     type=> 'str',       default=> 'ARRAY'}, },
    {name => 'index',     help=> 'valid index of array',     code=> 'return "value $value is out of range" if $value >= @$param',               parent=> 'int_pos',   default=>  0, 
                                                                                                          parameter => {   name => 'array',       type=> 'array_ref', default=> [1]    }, },
    {name =>'typed_array',help=> 'array with typed elements',code=> 'for my $i(0..$#$value){my $error = $param->check($value->[$i]); return "aray element $i $error" if $error}',
                                                                                                                                                parent=> 'array_ref', default=> [1],
                                                                                                          parameter => {   name => 'element_type',type=> 'type',                       }, }, 
    );
    for my $typedef (@standard_simple_types){
        my $type  = create_simple($typedef);                     die $type unless ref $type;
        my $error = add($type, $simple_sc{ $type->get_name });   die 'standard simple type definition error - '.$error if $error;
    }
    for my $typedef (@standard_param_types){
        my $type  = create_param($typedef);                      die $type unless ref $type;
        my $error = add($type, $param_sc{ $type->get_name });    die 'standard parametric type definition error - '.$error if $error;
    }
}
sub state {
    my %state = ();
    for my $type (values %simple_type) {
        my $type_name = $type->{'object'}->get_name;
        $state{'simple'}{ $type_name } = { 'object' => $type->{'object'}->state, file => $type->{'file'}, package => $type->{'package'}};
        $state{'simple'}{ $type_name }{'shortcut'} = $type->{'shortcut'} if exists $type->{'shortcut'};
    }
    for my $type_name (keys %param_type) {
        my $shortcut = $shortcut_by_name{'param'}{$type_name};
        for my $param_name (keys %{$param_type{$type_name}}) {
            my $type_def = $param_type{$type_name}{$param_name};
            $state{'param'}{$type_name}{$param_name} = { 'object' => $type_def->{'object'}->state, file => $type_def->{'file'}, package => $type_def->{'package'} };
            $state{'param'}{$type_name}{$param_name}{'shortcut'} = $shortcut_by_name{'param'}{$type_name} if exists $shortcut_by_name{'param'}{$type_name};
        }
    }
    \%state;
}
sub restate {
    my ($state) = @_;
    return if (caller)[0] ne 'Kephra::Base::Data::Type';
    return unless ref $state eq 'HASH' and ref $state->{'simple'} eq 'HASH' and ref $state->{'param'} eq 'HASH';
    %simple_type = %{$state->{'simple'}};
    %param_type = %{$state->{'param'}};
    for my $typedef (values %simple_type){
        $typedef->{'object'} = create_simple($typedef->{'object'});
        $name_by_shortcut{'simple'}{ $typedef->{'shortcut'} } = $typedef->{'name'} if exists $typedef->{'shortcut'};
    }
    for my $type_name (keys %param_type) {
        for my $param_name (keys %{$param_type{$type_name}}) {
            my $type_def = $param_type{$type_name}{$param_name};
            $type_def->{'object'} = create_param($type_def->{'object'});
            if (exists $type_def->{'shortcut'}){
                $name_by_shortcut{'param'}{ $type_def->{'shortcut'} } = $type_name; 
                $shortcut_by_name{'param'}{ $type_name }             = delete $type_def->{'shortcut'}; 
            }
        }
    }
}
################################################################################
sub new_type          {&create_simple}
sub create_simple     {  # ~name ~help ~code - .parent|~parent  $default     --> .type | ~errormsg
    my ($name, $help, $code, $parent, $default) = Kephra::Base::Data::Type::Simple::_unhash_arg_(@_);
    my $name_error = _validate_name_($name);
    return $name_error if $name_error;
    if (defined $parent){
        $parent = get($parent) if ref $parent ne $stclass;
        return "fourth or named argument 'parent' of type '$name' has to be a name of a standard type or a simple type object"
            if ref $parent ne $stclass;
    }
    Kephra::Base::Data::Type::Simple->new($name, $help, $code, $parent, $default);
}                       #             %{.type|~type - ~name $default }
sub create_param      { # ~name ~help %parameter ~code .parent|~parent - $default --> .ptype | ~errormsg
    my ($name, $help, $parameter, $code, $parent, $default) = Kephra::Base::Data::Type::Parametric::_unhash_arg_(@_);
    my $name_error = _validate_name_($name);
    return $name_error if $name_error;
    $parameter = get( $parameter ) unless ref $parameter;
    my $par_ref = ref $parameter;
    return "third or named argument 'parameter' has to be of type '$name', a name of a standard type or a parameter definition (hash ref)" 
        if $par_ref ne $stclass and $par_ref ne 'HASH';
    $parameter->{'type'} = get( $parameter->{'type'} ) if $par_ref eq 'HASH' and defined $parameter->{'type'} and $parameter->{'type'} ne $stclass;
    return "key 'type' in der parameter definition (hash ref) has to be a simple standard type name or a simple type object" 
        if $par_ref eq 'HASH' and ref $parameter->{'type'} ne $stclass;
    $parent = get($parent) if ref $parent ne $stclass;
    return "fifth or named argument 'parent' has to be a name of a standard type or a simple type object" if ref $parent ne $stclass;
    Kephra::Base::Data::Type::Parametric->new($name, $help, $parameter, $code, $parent, $default);
}
################################################################################
sub _validate_name_ {
    return "type name is not defined" unless defined $_[0];
    return "type name $_[0] contains none id character" if  $_[0] !~ /[a-zA-Z0-9_]/;
    return "type name $_[0] contains upper chase character" if  lc $_[0] ne $_[0];
    return "type name $_[0] is too long" if  length $_[0] > 12;
    return "type name $_[0] is not long enough" if  length $_[0] < 3;
    '';
}
sub _validate_shortcut_ {
    return "type shortcut name is not defined" unless defined $_[0];
    return "type shortcut $_[0] contains id character" if  $_[0] =~ /[a-zA-Z0-9_]/;
    return "type shortcut $_[0] is too long" if length $_[0] > 1;
    return "type shortcut $_[0] is not allowed" if exists $forbidden_shortcut{$_[0]};
    '';
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
    my $type_def = {object => $type, package => $package , file => $file };
    if (ref $type eq 'Kephra::Base::Data::Type::Parametric'){
        my $param_name = $type->get_parameter->get_name;
        my $name_error = _validate_name_( $type->get_parameter->get_name );
        return "type $type_name parameter: $name_error" if $name_error;
        return "type name $type_name with parameter $param_name is already in use" if exists $param_type{$type_name}{$param_name};
        if (defined $shortcut){
            my $type_with_same_sc = $name_by_shortcut{'param'}{ $shortcut };
            return "parametric type shortcut $shortcut is already used by different parametric type" if defined $type_with_same_sc and $type_with_same_sc ne $type_name;
            $name_by_shortcut{'param'}{ $shortcut } = $type_name;
            $shortcut_by_name{'param'}{ $type_name } = $shortcut;
        }
        $param_type{$type_name}{$param_name} = $type_def;
    } else {
        return "simple type name $type_name is already in use" if exists $simple_type{ $type_name };
        if (defined $shortcut){
            return "simple type shortcut $shortcut is already in use" if exists $name_by_shortcut{'simple'}{ $shortcut };
            $name_by_shortcut{'simple'}{ $shortcut } = $type_name;
            $type_def->{'shortcut'} = $shortcut;
        } 
        $simple_type{$type_name} = $type_def;
    }
    '';
}
sub remove {                                   # ~type - ~param              --> ~errormsg
    my ($type_name, $param_name) = @_;
    my $def = _get_(@_);
    return "type $type_name is unknown and can not be removed from standard" unless $def;
    my ($package, $file, $line) = caller();
    return "type $type_name is not owned by caller " unless $def->{'package'} eq $package and $def->{'file'} eq $file ;
    if (defined $param_name) { 
        delete $param_type{$type_name}{$param_name};
        unless (keys %{$param_type{$type_name}}){
            delete $param_type{$type_name};
            delete $name_by_shortcut{'param'}{ $shortcut_by_name{'param'}{$type_name} }, 
            delete                             $shortcut_by_name{'param'}{$type_name}    if exists $shortcut_by_name{'param'}{$type_name};
        }
    } else {  delete $simple_type{$type_name};    delete $name_by_shortcut{'simple'}{ $def->{'shortcut'}} if exists $def->{'shortcut'}  }
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
sub get {                                      # ~type - ~param              --> ~errormsg
    my ($tdef) = _get_(@_);
    ref $tdef ? $tdef->{'object'} : undef;
}

sub get_shortcut {                             # ~type - ~param              --> ~errormsg
    my ($type_name, $param_name) = @_;
    return $shortcut_by_name{'param'}{$type_name} if defined $param_name;
    exists $simple_type{$type_name} ? $simple_type{$type_name}{'shortcut'} : undef;
}

sub list_names        {                        # - ~kind ~pname              --> @~type|@~ptype|@~param
    my ($kind, $type_name) = @_;
    if (defined $kind and index($kind, 'param') > -1) {
        if (defined $type_name){
            sort( keys %{$param_type{$type_name}}) if exists $param_type{$type_name}
        } else { sort( keys %param_type) }
    } else { sort( keys %simple_type) }
}
sub _key_from_kind_ {
	return 'simple' if not $_[0] or $_[0] eq 'simple';
	return 'param' if index($_[0], 'param') > -1;
}
sub list_shortcuts    {                        #                             --> @~shortcut
    my ($kind) = _key_from_kind_(@_);
    return unless defined $kind;
    sort keys %{$name_by_shortcut{ $kind }};
}
sub resolve_shortcut  {                        # ~shortcut - ~param          -->  ~type
    my ($shortcut, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    $name_by_shortcut{ $kind }{$shortcut};
}
################################################################################
sub is_type_known { &is_known }
sub is_known      { ref _get_(@_) ? 1 :0 }     # ~type - ~param              -->  ?
sub is_initial    {                            # ~type - ~param              -->  ?
    my ($tdef) = _get_(@_);
    return unless ref $tdef;
    ($tdef->{'file'} eq __FILE__ and $tdef->{'package'} eq __PACKAGE__) ? 1 : 0;
}
sub is_owned {
    my ($tdef) = _get_(@_);
    return unless ref $tdef;
    my ($package, $file, $line) = caller();
    ($tdef->{'file'} eq $file and $tdef->{'package'} eq $package) ? 1 : 0 ;
}
################################################################################
sub check_type    {&check_simple}
sub check_simple  {                            # ~name $val                  --> ~errormsg
    my ($type_name, $value) = @_;
    my $type = get( $type_name );
    return "no type named $type_name known in the standard" unless ref $type;
    $type->check($value);
}
sub check_param  {                             # ~name $val                  --> ~errormsg
    my ($type_name, $param_name, $value, $param_value) = @_;
    my $type = get( $type_name, $param_name );
    return "no type $type_name with parameter $param_name is known in the standard" unless ref $type;
    $type->check($value, $param_value);
}
sub guess_type   {&guess}
sub guess        {                             # $val                        --> @name
    my ($value) = @_;
    my @name;
    for my $name (list_names()) {push @name, $name unless check_simple($name, $value)}
    sort @name;
}
################################################################################
1;

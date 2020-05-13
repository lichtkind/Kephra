use v5.20;
use warnings;
use feature "switch";
no warnings 'experimental::smartmatch';

# extendable collection of simple and parametric type objects + deps resolver
#      serialize type keys: object, shortcut, file, package

package Kephra::Base::Data::Type::Store;
our $VERSION = 0.5;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;
my $btclass = 'Kephra::Base::Data::Type::Basic';
my $ptclass = 'Kephra::Base::Data::Type::Parametric';
##############################################################################
sub new {
    my ($pkg) = @_;
    bless {forbid_shortcut =>[], basic_type => {}, param_type => {}, basic_name_by_shortcut => {}, param_name_by_shortcut => {}, param_shortcut_by_name => {}, open => 1//$_[1]};
}
sub state {
    my ($self) = @_;
    my %state = ('basic_type' => {}, 'param_type' => {}, forbid_shortcut => [@{$self->{'forbid_shortcut'}}], open => $self->{'open'});
    my $base = $state{'basic_type'};
    for my $type (values %{$self->{'basic_type'}}) {
        my $type_name = $type->{'object'}->get_name;
        $base->{ $type_name } = { 'object' => $type->{'object'}->state, file => $type->{'file'}, package => $type->{'package'}};
        $base->{ $type_name }{'shortcut'} = $type->{'shortcut'} if exists $type->{'shortcut'};
    }
    $base = $state{'param_type'};
    for my $type_name (keys %{$self->{'param_type'}}) {
        my $shortcut = $self->{'param_shortcut_by_name'}{$type_name};
        for my $param_name (keys %{$self->{'param_type'}{$type_name}}) {
            my $type_def = $self->{'param_type'}{$type_name}{$param_name};
            $base->{$type_name}{$param_name} = { 'object' => $type_def->{'object'}->state, file => $type_def->{'file'}, package => $type_def->{'package'} };
            $base->{$type_name}{$param_name}{'shortcut'} = $shortcut if defined $shortcut;
        }
    }
    \%state;
}
sub restate {
    my ($pkg, $state) = @_;
    return unless ref $state eq 'HASH' and ref $state->{'basic'} eq 'HASH' and ref $state->{'param'} eq 'HASH';
    my $self => __PACKAGE__->new();
    $self->{$_} = $state->{$_} for qw/basic_type param_type forbid_shortcut open/;
    for my $type_def (values %{$self->{'basic_type'}}){
        $type_def->{'object'} = Kephra::Base::Data::Type::Basic->restate($type_def->{'object'});
        $self->{'basic_name_by_shortcut'}{ $type_def->{'shortcut'} } = $type_def->{'name'} if exists $type_def->{'shortcut'};
    }
    for my $param_type (values %{$self->{'param_type'}}) {
        for my $type_def (values %$param_type) {
            my $type_name = $type_def->{'name'};
            $type_def->{'object'} = Kephra::Base::Data::Type::Parametric->restate($type_def->{'object'});
            if (exists $type_def->{'shortcut'}){
                $self->{'param_name_by_shortcut'}{ $type_def->{'shortcut'} } = $type_name; 
                $self->{'param_shortcut_by_name'}{ $type_name }             = delete $type_def->{'shortcut'}; 
            }
        }
    }
    $self;
}
################################################################################
sub new_basic_type   {  # ~name ~help ~code - .parent|~parent  $default     --> .type | ~errormsg
    my ($self, $name, $help, $code, $parent, $default, $shortcut) = @_;
    return 'can not add to a finalized type store' unless $self->{'open'};
    $shortcut = $name->{'shortcut'} if ref $name eq 'HASH';
    ($name, $help, $code, $parent, $default) = Kephra::Base::Data::Type::Basic::_unhash_arg_(@_);
    my $name_error = _validate_name_($name);
    return $name_error if $name_error;
    if (defined $parent){
        $parent = $self->get_type($parent) if ref $parent ne $btclass;
        return "type store can not create basic type '$name', because fourth or named argument 'parent' has to be a basic type object or name a stored basic type"
            if ref $parent ne $btclass;
    }
    my $type = Kephra::Base::Data::Type::Basic->new($name, $help, $code, $parent, $default);
    return "type store can not create basic type '$name', because $type" if ref $type ne $btclass;
    $parent = $self->add_type($type, $shortcut);
}                       #             %{.type|~type - ~name $default }
sub new_param_type    { # ~name ~help %parameter ~code .parent|~parent - $default --> .ptype | ~errormsg
    my ($self, $name, $help, $parameter, $code, $parent, $default, $shortcut) = @_;
    return 'can not add to a finalized type store' if $self->{'final'};
    $shortcut = $name->{'shortcut'} if ref $name eq 'HASH';
#Kephra::Base::Data::Type::Parametric::_unhash_arg_(@_);
    my $name_error = _validate_name_($name);
    return $name_error if $name_error;
    $parameter = get( $parameter ) unless ref $parameter;
    my $par_ref = ref $parameter;
    return "third or named argument 'parameter' has to be of type '$name', a name of a standard type or a parameter definition (hash ref)" 
        if $par_ref ne $btclass and $par_ref ne 'HASH';
    $parameter->{'type'} = get( $parameter->{'type'} ) if $par_ref eq 'HASH' and defined $parameter->{'type'} and $parameter->{'type'} ne $btclass;
    return "key 'type' in der parameter definition (hash ref) has to be a simple standard type name or a simple type object" 
        if $par_ref eq 'HASH' and ref $parameter->{'type'} ne $btclass;
    $parent = get($parent) if ref $parent ne $btclass;
    return "fifth or named argument 'parent' has to be a name of a standard type or a simple type object" if ref $parent ne $btclass;
    Kephra::Base::Data::Type::Parametric->new($name, $help, $parameter, $code, $parent, $default);
}
################################################################################
sub _validate_name_ {
    my $self = shift;
    return "type name is not defined" unless defined $_[0];
    return "type name $_[0] contains none id character" if  $_[0] !~ /[a-zA-Z0-9_]/;
    return "type name $_[0] contains upper chase character" if  lc $_[0] ne $_[0];
    return "type name $_[0] is too long" if  length $_[0] > 12;
    return "type name $_[0] is not long enough" if  length $_[0] < 3;
    '';
}
sub _validate_shortcut_ {
    my $self = shift;
    return "type shortcut is undefined" unless defined $_[0];
    return "type shortcut $_[0] contains id character" if  $_[0] =~ /[a-zA-Z0-9_]/;
    return "type shortcut $_[0] is too long" if length $_[0] > 1;
    return "type shortcut $_[0] is not allowed" if $_[0] ~~ $self->{'forbid_shortcut'};
    '';
}

sub add_type {                                 # .type - ~shortcut           --> ~errormsg
    my ($self, $type, $shortcut) = @_;
    return 'can not add to a closed type store' unless $self->{'open'};
    return "$type is not a type object and can not be added to the standard" if ref $type ne $btclass and ref $type ne 'Kephra::Base::Data::Type::Parametric';
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
sub add_shortcut      {                    # .tstore ~kind ~type ~shortcut   --> ~errormsg
    my ($self, $type, $shortcut) = @_;
    return 'can not add to a closed type store' unless $self->{'open'};
}
sub remove {                               # ~type - ~param                  --> ~errormsg
    my ($self, $type_name, $param_name) = @_;
    return 'can not remove from a closed type store' unless $self->{'open'};
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
sub remove_shortcut   {                    # .tstore ~kind ~shortcut         --> ~errormsg
    my ($self, $kind, $shortcut) = @_;
    return 'can not remove from a closed type store' unless $self->{'open'};
}
sub is_open{ $_[0]->{'open'} }                                               # --> ?
sub close  { return 0 if $_[0]->{'open'} eq 'open'; $_[0]->{'open'} = 0; 1 } # --> ?
################################################################################
sub _get_ {
    my ($type_name, $param_name) = @_;
    return unless defined $type_name;
    if (defined $param_name) {
        $param_type{$type_name}{$param_name} if exists $param_type{$type_name} and exists $param_type{$type_name}{$param_name};
    } else {
        $simple_type{$type_name}             if exists $simple_type{$type_name};
    }
}
sub get_type {                                 # ~type - ~param              --> ~errormsg
    my ($tdef) = _get_(@_);
    ref $tdef ? $tdef->{'object'} : undef;
}

sub get_shortcut {                             # ~type - ~param              --> ~errormsg
    my ($type_name, $param_name) = @_;
    return $shortcut_by_name{'param'}{$type_name} if defined $param_name;
    exists $simple_type{$type_name} ? $simple_type{$type_name}{'shortcut'} : undef;
}
sub resolve_shortcut  {                        # ~shortcut - ~param          -->  ~type
    my ($shortcut, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    $name_by_shortcut{ $kind }{$shortcut};
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
    return 'basic' if not $_[0] or $_[0] eq 'basic';
    return 'param' if index($_[0], 'param') > -1;
}
sub list_shortcuts    {                        #                             --> @~shortcut
    my ($kind) = _key_from_kind_(@_);
    return unless defined $kind;
    sort keys %{$name_by_shortcut{ $kind }};
}
sub forbid_shortcuts  {  # .tstore @~shortcut              --> ?
    
    
    
}
################################################################################
sub is_known      { ref _get_(@_) ? 1 :0 }     # ~type - ~param              -->  ?
sub is_owned {
    my ($tdef) = _get_(@_);
    return unless ref $tdef;
    my ($package, $file, $line) = caller();
    ($tdef->{'file'} eq $file and $tdef->{'package'} eq $package) ? 1 : 0 ;
}
################################################################################
sub check_basic  {                             # ~name $val                  --> ~errormsg
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
sub guess_basic {                              # $val                        --> @name
    my ($value) = @_;
    my @name;
    for my $name (list_names()) {push @name, $name unless check_simple($name, $value)}
    sort @name;
}
################################################################################
4;

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
sub add_type {                                 # .type - ~shortcut           --> ~errormsg
    my ($self, $type, $shortcut) = @_;
    return 'can not add to a closed type store' unless $self->{'open'};
    if (ref $type eq 'HASH'){
        if (exists $type->{'parameter'}){
            if (ref $type->{'parameter'}{'type'} ne $btclass){
                my $param_type = $self->get_type($type->{'parameter'}{'type'});
                return "parameter type '$type->{'parameter'}{'type'}' is unknown to this type store" unless ref $param_type;
                $type->{'parameter'}{'type'} = $param_type;
            }
            if (ref $type->{'parent'} ne $btclass){
                my $parent = $self->get_type($type->{'parent'});
                $parent = $self->get_type($type->{'parent'}, $type->{'parameter'}{'type'}->get_name) unless ref $parent;
                return "'parent' type '$type->{parent}' is unknown to this type store" unless ref $parent;
                $type->{'parent'} = $parent;
            }
            $type = Kephra::Base::Data::Type::Parametric->new($type);
        } else {
            if (ref $type->{'parent'} ne $btclass){
                my $parent = $self->get_type($type->{'parent'});
                return "'parent' type '$type->{parent}' is unknown to this type store" unless ref $parent;
                $type->{'parent'} = $parent;
            }
            $type = Kephra::Base::Data::Type::Basic->new($type);
        }
        return "type store can not create and add type, because $type" unless ref $type;
    }
    return "type store can not add type, because $type is neither instance of $btclass or $ptclass" if ref $type ne $btclass and ref $type ne $ptclass;
    my $type_name = $type->get_name;
    my $name_error = $self->_validate_type_name_( $type_name );
    return "type store can not add type $type_name, because $name_error" if $name_error;
    if (defined $shortcut){
        my $shortcut_error = $self->_validate_shortcut_( $shortcut );
        return "type store can not add type $type_name with shortcut $shortcut, because $shortcut_error" if $shortcut_error;
    }
    my ($package, $file, $line) = caller();
    my $type_def = {object => $type, package => $package , file => $file };
    if (ref $type eq $ptclass){
        my $param_name = $type->get_parameter->get_name;
        my $name_error = $self->_validate_type_name_( $param_name );
        return "type store can not add type $type_name, because of its parameter name: $name_error" if $name_error;
        return "type 'name' $type_name with 'parameter' 'name' $param_name is already in use" if exists $self->{'param_type'}{$type_name} 
                                                                                             and exists $self->{'param_type'}{$type_name}{$param_name};
        if (defined $shortcut){
            my $type_with_same_sc = $self->{'param_name_by_shortcut'}{ $shortcut };
            return "can not add type $type_name, because parametric type shortcut $shortcut is already in use" if defined $type_with_same_sc and $type_with_same_sc ne $type_name;
            $self->{'param_name_by_shortcut'}{ $shortcut } = $type_name;
            $self->{'param_shortcut_by_name'}{ $type_name } = $shortcut;
        }
        $self->{'param_type'}{$type_name}{$param_name} = $type_def;
    } else {
        return "basic type 'name' $type_name is already in use" if exists $self->{'basic_type'}{ $type_name };
        if (defined $shortcut){
            return "basic type shortcut $shortcut of type $type_name is already in use" if exists $self->{'basic_name_by_shortcut'}{ $shortcut };
            $self->{'basic_name_by_shortcut'}{ $shortcut } = $type_name;
            $type_def->{'shortcut'} = $shortcut;
        } 
        $self->{'basic_type'}{$type_name} = $type_def;
    }'';
}
sub add_shortcut      {                    # .tstore ~kind ~type ~shortcut   --> ~errormsg
    my ($self, $kind, $type_name, $shortcut) = @_;
    return 'can not add to a closed type store' unless $self->{'open'};
    if (_key_from_kind_($kind) eq 'param'){
        return "parametric type shortcut $shortcut is already in use" if exists $self->{'param_name_by_shortcut'}{ $shortcut };
        return "parametric type $type_name is unknown to this store" unless exists $self->{'param_type'}{$type_name};
        $self->{'param_name_by_shortcut'}{ $shortcut } = $type_name;
        $self->{'param_shortcut_by_name'}{ $type_name } = $shortcut;
    } else {
        return "basic type shortcut $shortcut is already in use" if exists $self->{'basic_name_by_shortcut'}{ $shortcut };
        return "basic type $type_name is unknown to this store" unless exists $self->{'basic_type'}{$type_name};
        $self->{'basic_name_by_shortcut'}{ $shortcut } = $type_name;
        $self->{'basic_type'}{$type_name}{'shortcut'} = $shortcut;
    }'';
}
sub remove_type {                          # ~type - ~param                  --> .type|~errormsg
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
    '';
}
sub is_open{ $_[0]->{'open'} }                                               # --> ?
sub close  { return 0 if $_[0]->{'open'} eq 'open'; $_[0]->{'open'} = 0; 1 } # --> ?
################################################################################
sub _validate_type_name_ {
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
sub _key_from_kind_ {
    return 'basic' if not $_[0] or $_[0] eq 'basic';
    return 'param' if index($_[0], 'param') > -1;
}
sub _get_type_def_ {
    my ($self, $type_name, $param_name) = @_;
    return unless defined $type_name;
    if (defined $param_name) {
        $self->{'param_type'}{$type_name}{$param_name} if exists $self->{'param_type'}{$type_name} and exists $self->{'param_type'}{$type_name}{$param_name};
    } else {
        $self->{'basic_type'}{$type_name}              if exists $self->{'basic_type'}{$type_name};
    }
}
################################################################################
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

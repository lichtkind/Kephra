use v5.20;
use warnings;
use feature "switch";
no warnings 'experimental::smartmatch';

# extendable collection of simple and parametric type objects + dependency resolver
#       serialize type keys: object, shortcut, file, package
#       multiple parametric types with same name and different parameters must have same owner and shortcut (basic type shortcuts have own name space)
#       open stores cannot be closed (like normal ones can) 

package Kephra::Base::Data::Type::Namespace;
our $VERSION = 0.13;
use Kephra::Base::Data::Type::Basic;             my $btclass = 'Kephra::Base::Data::Type::Basic';
use Kephra::Base::Data::Type::Parametric;        my $ptclass = 'Kephra::Base::Data::Type::Parametric';
################################################################################
sub new {      # - |'open'   --> .tstore
    my ($pkg) = @_;
    bless {basic_type => {}, param_type => {}, open => $_[1]//1,
           basic_name_by_shortcut => {}, param_name_by_shortcut => {}, forbid_shortcut => []};
}
sub state {    #            --> %state
    my ($self) = @_;
    my %state = ('basic_type' => {}, 'param_type' => {}, forbid_shortcut => [@{$self->{'forbid_shortcut'}}], open => $self->{'open'});
    for my $type_def (values %{$self->{'basic_type'}}) {
        my $type_name = $type_def->{'object'}->name;
        $state{'basic_type'}{ $type_name } = { object => $type_def->{'object'}->state,
                                               file => $type_def->{'file'}, package => $type_def->{'package'}};
        $state{'basic_type'}{ $type_name }{'shortcut'} = $type_def->{'shortcut'} if exists $type_def->{'shortcut'};
    }
    for my $type_name (keys %{$self->{'param_type'}}) {
        my $type_def = $self->{'param_type'}{ $type_name };
        $state{'param_type'}{ $type_name } = { file => $type_def->{'file'}, package => $type_def->{'package'}, object => {} };
        $state{'param_type'}{ $type_name }{'shortcut'} = $type_def->{'shortcut'} if exists $type_def->{'shortcut'};
        $state{'param_type'}{ $type_name }{'object'}{$_} = $type_def->{'object'}{$_}->state for keys %{$type_def->{'object'}};
    }
    \%state;
}
sub restate {  # %state     --> .tstore
    my ($pkg, $state) = @_;
    return unless ref $state eq 'HASH' and ref $state->{'basic_type'} eq 'HASH' and ref $state->{'param_type'} eq 'HASH';
    my $self = bless {};
    $self->{$_} = $state->{$_} for qw/basic_type param_type forbid_shortcut open/;
    for my $type_name (keys %{$self->{'basic_type'}}){
        my $type_def = $self->{'basic_type'}{ $type_name };
        $type_def->{'object'} = Kephra::Base::Data::Type::Basic->restate( $type_def->{'object'} );
        $self->{'basic_name_by_shortcut'}{ $type_def->{'shortcut'} } = $type_name if exists $type_def->{'shortcut'};
    }
    for my $type_name (keys %{$self->{'param_type'}}) {
        my $type_def = $self->{'param_type'}{ $type_name };
        $type_def->{'object'}{$_} = Kephra::Base::Data::Type::Parametric->restate( $type_def->{'object'}{$_} ) for keys %{$type_def->{'object'}};
        $self->{'param_name_by_shortcut'}{ $type_def->{'shortcut'} } = $type_name if exists $type_def->{'shortcut'};
    }
    $self;
}
################################################################################
sub is_open{ $_[0]->{'open'} } #(open store cant be closed)                  # --> ?
sub close  { return 0 if $_[0]->{'open'} eq 'open' or not $_[0]->{'open'}; $_[0]->{'open'} = 0; 1 } # --> ?
################################################################################
sub list_type_names   {                        # - ~kind ~ptype              --> @~btype|@~ptype|@~param
    my ($self, $kind, $type_name) = @_;        # kind = 'basic' | 'param'
    ($kind = _key_from_kind_($kind)) or return;
    if (defined $type_name){
        return unless exists $self->{'param_type'}{$type_name} and $kind eq 'param';
        return sort keys %{ $self->{'param_type'}{$type_name}{'object'} };
    }
    sort keys %{$self->{$kind.'_type'}};
}
sub list_shortcuts    {                        #                             --> @~shortcut
    my ($self, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    sort keys( %{$self->{$kind.'_name_by_shortcut'}});
}
sub list_forbidden_shortcuts { @{$_[0]->{'forbid_shortcut'}} ? sort(@{$_[0]->{'forbid_shortcut'}}) : undef } # .tstore     --> @~shortcut
################################################################################
sub add_type {                                 # .type - ~shortcut           --> ~errormsg
    my ($self, $type, $shortcut) = @_;
    return 'can not add to a closed type store '.$self->{'open'} unless $self->{'open'};
    if (ref $type eq 'HASH'){
        if (exists $type->{'parameter'} or ref $type->{'parent'} eq $ptclass){
                 $type = Kephra::Base::Data::Type::Parametric->new($type);
        } else { $type = Kephra::Base::Data::Type::Basic->new($type) }
        return "type store can not create type from hash definition, because $type" unless ref $type;
    }

    return "type store can not add type, because $type is neither instance of $btclass or $ptclass" if ref $type ne $btclass and ref $type ne $ptclass;
    my $kind = ref $type eq $ptclass ? 'param' : 'basic';
    my $type_name = $type->name;
    my $name_error = Kephra::Base::Data::Type::Basic::_check_name( $type_name );
    return "type store can not add type $type_name, because $name_error" if $name_error;
    if (defined $shortcut){
        my $shortcut_error = $self->_validate_shortcut_( $shortcut );
        return "type store can not add type $type_name with shortcut $shortcut, because $shortcut_error" if $shortcut_error;
        return "can not add type $type_name, because type shortcut $shortcut is already in use" if exists $self->{$kind.'_name_by_shortcut'}{ $shortcut } 
                                                                                                      and $self->{$kind.'_name_by_shortcut'}{ $shortcut } ne $type_name;
    }
    my ($package, $file, $line) = caller();
    my $type_def = {package => $package , file => $file };

    $type_def->{'shortcut'} = $shortcut if defined $shortcut;
    if (ref $type eq $ptclass){
        my $param_name = $type->parameter->name;
        my $name_error = Kephra::Base::Data::Type::Basic::_check_name( $param_name );
        return "type store can not add type $type_name, because of its parameter name: $name_error" if $name_error;
        if (exists $self->{'param_type'}{$type_name}){
            $type_def = $self->{'param_type'}{$type_name};
            return "type 'name' $type_name with 'parameter' 'name' $param_name is already in use" if ref $type_def->{'object'}{$param_name};
            return "type 'name' $type_name with different paramter than $param_name was already created by different package" if $type_def->{'file'} ne $file or $type_def->{'package'} ne $package;
        } else {
            $self->{'param_type'}{$type_name} = $type_def;
        }
        $type_def->{'object'}{$param_name} = $type;
        $self->{'param_name_by_shortcut'}{ $shortcut } = $type_name if defined $shortcut;
    } else {
        return "basic type 'name' $type_name is already in use" if exists $self->{'basic_type'}{ $type_name };
        $type_def->{'object'} = $type;
        $self->{'basic_type'}{$type_name} = $type_def;
        $self->{'basic_name_by_shortcut'}{ $shortcut } = $type_name if defined $shortcut;
    }'';
}
sub remove_type {                          # ~type - ~param                  --> .type|~errormsg
    my ($self, $type_name, $param_name) = @_;
    return 'can not remove from a closed type store' unless $self->{'open'};
    my $type_def = _get_type_def_(@_);
    return "type $type_name is unknown and can not be removed from store" unless ref $type_def;
    my ($package, $file, $line) = caller();
    return "type $type_name can not be deleted by caller ($package), because it is no the owner" if $type_def->{'package'} ne $package or $type_def->{'file'} ne $file ;
    if (defined $param_name) {
        if ((keys %{ $type_def->{'object'} }) == 1){
            delete $self->{'param_type'}{$type_name};
            delete $self->{'param_name_by_shortcut'}{ $type_def->{'shortcut'}} if exists $type_def->{'shortcut'};
        }
        return delete $type_def->{'object'}{$param_name};
    } else {  
        delete $self->{'basic_type'}{$type_name};
        delete $self->{'basic_name_by_shortcut'}{ $type_def->{'shortcut'}} if exists $type_def->{'shortcut'};
        return $type_def->{'object'};
    }
}
sub get_type {                                 # ~type - ~param              --> ~errormsg
    my ($self, $type_name, $param_name) = @_;
    ($type_name, $param_name) = @$type_name if ref $type_name eq 'ARRAY';
    if (defined $param_name){ return $self->{'param_type'}{$type_name}{'object'}{$param_name} if exists $self->{'param_type'}{$type_name} }
    else                    { return $self->{'basic_type'}{$type_name}{'object'}              if exists $self->{'basic_type'}{$type_name} }
    undef;
}
################################################################################
sub is_type_known { ref _get_type_def_(@_) ? 1 : 0 } #.tstore ~type - ~param --> ?
sub is_type_owned {                                 # .tstore ~type - ~param --> ?
    my ($tdef) = _get_type_def_(@_);
    return 0 unless ref $tdef;
    my ($package, $file, $line) = caller();
    ($tdef->{'file'} eq $file and $tdef->{'package'} eq $package) ? 1 : 0;
}
################################################################################
sub add_shortcut      {                    # .tstore ~kind ~type ~shortcut   --> ~errormsg
    my ($self, $kind, $type_name, $shortcut) = @_;
    return 'can not add to a closed type store' unless $self->{'open'};
    (my $key = _key_from_kind_($kind)) or return "first argument has to be 'kind' of type ('basic' or 'param[etric]', not '$kind') you want add shortcut for";
    my ($package, $file, $line) = caller();
    return "$key type shortcut $shortcut is already in use, can not add it" if exists $self->{$key.'_name_by_shortcut'}{ $shortcut };
    return "$key type $type_name is unknown to this store, can not add shortcut to it" unless exists $self->{$key.'_type'}{$type_name};
    return "$key type $type_name has already a shortcut, please remove it first" if exists $self->{$key.'_type'}{$type_name}{'shortcut'};
    return "$key type $type_name has another owner, can not add shortcut name $shortcut"
       if $self->{$key.'_type'}{$type_name}{'file'} ne $file or $self->{$key.'_type'}{$type_name}{'package'} ne $package;
    $self->{$key.'_type'}{$type_name}{'shortcut'} = $shortcut;
    $self->{$key.'_name_by_shortcut'}{ $shortcut } = $type_name;
    '';
}
sub remove_shortcut   {                    # .tstore ~kind ~shortcut         --> ~errormsg
    my ($self, $kind, $shortcut) = @_;
    return 'can not remove from a closed type store' unless $self->{'open'};
    (my $key = _key_from_kind_($kind)) or return "first argument has to be 'kind' of type ('basic' or 'param[etric]', not '$kind') you want add shortcut for";
    return "$key type shortcut $shortcut is not known by this type store and can not be deleted" unless exists $self->{$key.'_name_by_shortcut'}{ $shortcut };
    my $type_name = $self->{$key.'_name_by_shortcut'}{ $shortcut };
    my $type_def = $self->{$key.'_type'}{$type_name};
    my ($package, $file, $line) = caller();
    return "$key type $type_name has a different owner than caller, can not delete shortcut $shortcut from type store" if $type_def->{'file'} ne $file or $type_def->{'package'} ne $package;
    delete $self->{$key.'_name_by_shortcut'}{ delete $type_def->{'shortcut'} };
    '';
}
sub type_shortcut {                             # ~kind ~type                 --> ~errormsg
    my ($self, $kind, $type_name) = @_;
    return unless defined $type_name;
    ($kind = _key_from_kind_($kind)) or return;
    (exists $self->{$kind.'_type'}{$type_name}) ? $self->{$kind.'_type'}{$type_name}{'shortcut'} : undef;
}
sub resolve_shortcut  {                        # ~kind ~shortcut             --> ~type|undef
    my ($self, $kind, $shortcut) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    $self->{$kind.'_name_by_shortcut'}{$shortcut};
}
sub forbid_shortcuts  {                        # .tstore @~shortcut          --> ~errormsg
    my ($self) = shift;
    return 'can not remove from a closed type store' unless $self->{'open'};
    my %sc = map {$_ => 1} @{$self->{'forbid_shortcut'}}, keys %{$self->{'basic_name_by_shortcut'}}, keys %{$self->{'param_name_by_shortcut'}};
    for (@_){push @{$self->{'forbid_shortcut'}}, $_ unless exists $sc{$_}; $sc{$_}++ };
}
################################################################################
sub _validate_shortcut_ {
    my $self = shift;
    return "type shortcut is undefined" unless defined $_[0];
    return "type shortcut $_[0] contains id character" if  $_[0] =~ /[a-z0-9_]/;
    return "type shortcut $_[0] is too long" if length $_[0] > 1;
    return "type shortcut $_[0] is not allowed" if $_[0] ~~ $self->{'forbid_shortcut'};
    '';
}
sub _key_from_kind_ {
    return 'basic' if not $_[0] or $_[0] eq 'basic';
    return 'param' if index($_[0], 'para') > -1;
}
sub _get_type_def_ {
    my ($self, $type_name, $param_name) = @_;
    return unless defined $type_name;
    if (defined $param_name) { $self->{'param_type'}{$type_name} if exists $self->{'param_type'}{$type_name} and exists $self->{'param_type'}{$type_name}{'object'}{$param_name} }
    else                     { $self->{'basic_type'}{$type_name}                                                          }
}
################################################################################

4;
__END__
sub can_substitude_names {   # %type_def              --> =amount
    my $type_def = shift;
    return 0 unless ref $type_def eq 'HASH';
    (defined $type_def->{'parent'} and not ref $type_def->{'parent'})         +
    (defined $type_def->{'parent'} and ref $type_def->{'parent'} eq 'ARRAY')  +
    (exists $type_def->{'parameter'} and not ref $type_def->{'parameter'})    +
    (ref $type_def->{'parameter'} eq 'HASH' and exists $type_def->{'parameter'}{'parent'} and not ref $type_def->{'parameter'}{'parent'});
}
sub substitude_names {   # %type_def @.type_store      --> =amount
    my $type_def = shift;
    return 0 unless ref $type_def eq 'HASH';
    my $amount = 0;
    for my $store (@_){
        next unless ref $store eq 'Kephra::Base::Data::Type::Store';
        if (defined $type_def->{'parent'} and not ref $type_def->{'parent'}){
            my $tmp = $store->get_type( $type_def->{'parent'} );              $type_def->{'parent'} = $tmp, $amount++ if ref $tmp;
        } elsif (ref $type_def->{'parent'} eq 'ARRAY'){
            my $tmp = $store->get_type( @{$type_def->{'parent'}} );           $type_def->{'parent'} = $tmp, $amount++ if ref $tmp;
        }
        if (ref $type_def->{'parameter'} eq 'HASH' and exists $type_def->{'parameter'}{'parent'} and not ref $type_def->{'parameter'}{'parent'}){
            my $tmp = $store->get_type($type_def->{'parameter'}{'parent'});   $type_def->{'parameter'}{'parent'} = $tmp, $amount++ if ref $tmp;
        } elsif (exists $type_def->{'parameter'} and not ref $type_def->{'parameter'}){
            my $tmp = $store->get_type( $type_def->{'parameter'} );           $type_def->{'parameter'} = $tmp, $amount++ if ref $tmp;
        }
    }
    $amount;
}
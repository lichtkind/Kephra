use v5.20;
use warnings;
use feature "switch";
no warnings 'experimental::smartmatch';

# extendable collection of simple and parametric type objects with symbol, dependency and ownership resolver
#       multiple parametric types with same name and different parameters must have same owner and shortcut
#       open stores ($self->{open} eq 'open') cannot be closed (like normal == 0 | 1 = ?) 

package Kephra::Base::Data::Type::Namespace;
our $VERSION = 0.13;
use Kephra::Base::Data::Type::Basic;             my $btclass = 'Kephra::Base::Data::Type::Basic';
use Kephra::Base::Data::Type::Parametric;        my $ptclass = 'Kephra::Base::Data::Type::Parametric';
#### constructor, serialisation ################################################
sub new {      # - |'open'   --> .tstore
    my ($pkg) = @_;                      #  0|1|'open' (stay)    __PACKAGE__  __FILE__
    bless {basic_type => {}, param_type => {}, open => $_[1]//1, 
           basic_owner => {}, param_owner => {}, basic_origin => {}, param_origin => {},
           basic_symbol => {}, param_symbol => {}, forbid_symbol => {}};
}
sub state {    #            --> %state
    my ($self) = @_;
    my %state = (basic_owner => {%{$self->{'basic_owner'}}}, basic_origin => {%{$self->{'basic_origin'}}}, 
                 basic_shortcut => {%{$self->{'basic_shortcut'}}},  param_shortcut => {%{$self->{'param_shortcut'}}},
                 forbid_shortcut => [@{$self->{'forbid_shortcut'}}],  open => $self->{'open'}  );
    $state{'basic_type'}{$_->name} = $_->state for values %{$self->{'basic_type'}};
    for my $type_name (keys %{$self->{'param_type'}}) {
        $state{'param_type'}{$type_name}{$_->parameter->name} = $_->state for values %{$self->{'param_type'}{$type_name}};
        $state{'param_owner'}{$type_name} = {%{$self->{'param_owner'}{$type_name}}} if exists $self->{'param_owner'}{$type_name};
        $state{'param_origin'}{$type_name} = {%{$self->{'param_origin'}{$type_name}}} if exists $self->{'param_origin'}{$type_name};
    }
    \%state;
}
sub restate {  # %state     --> .tstore
    my ($pkg, $state) = @_;
    return unless ref $state eq 'HASH' and ref $state->{'basic_type'} eq 'HASH' and ref $state->{'param_type'} eq 'HASH';
    $state{'basic_type'}{$_->{'name'}} = Kephra::Base::Data::Type::Basic->restate($_} for values %{$state->{'basic_type'}};
    for my $type_name (keys %{$state->{'param_type'}}) {
        $state{'param_type'}{$type_name}{$_->{'parameter'}{'name'}} = Kephra::Base::Data::Type::Parametric->restate($_)
            for values %{$self->{'param_type'}{$type_name}};
    }
    bless $state;
}

################################################################################
sub is_open{ $_[0]->{'open'} } #(open store cant be closed)                  # --> ?
sub close  { return 0 if $_[0]->{'open'} eq 'open' or not $_[0]->{'open'}; $_[0]->{'open'} = 0; 1 } # --> ?

##### type definition handling (resolving type names) ##########################
sub _root_parent_name {
    my ($type_def) = @_;
    return unless defined $type_def;
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' and exists $type_def->{'parent'};
    return $type_def if ref $type_def eq 'ARRAY' or (not ref $type_def and $type_def);
}
sub _parameter_root_name {
    my ($self, $type_def) = @_;
    return unless defined $type_def;
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' 
                                        and exists $type_def->{'parent'} and not exists $type_def->{'parameter'};
    _root_parent_name( $type_def->{'parameter'} ) if $type_def eq 'HASH' and exists $type_def->{'parameter'};
}
sub need_resolve { grep {$_} _root_parent_name($_[1]), _parameter_root_name($_[1]) }  # _ .typedef -->  @~ names == $: +solved = 0|1|2
sub can_resolve { grep {$_[0]->has_type($_) _root_parent_name($_[1]), _parameter_root_name($_[1]) } # .typedef --> +solved = 0|1|2
sub resolve_names {                                 # .typedef --> +solved = -2|-1|0|1|2 (number of resolved, negative are still open)
    my ($self, $type_def) = @_;
# get_type {                                 # ~type -- ~param       --> .btype|.ptype|undef
# has_type {                                 # ~type -- ~param       --> .btype|.ptype|undef
}

#### type handling (add restore lookup) ########################################
sub add_type {                                      # .type - ~shortcut ?public      --> ~errormsg
    my ($self, $type, $symbol, $public) = @_;
    return 'can not add to a closed type store ' unless $self->{'open'};
    if (ref $type eq 'HASH'){
        $self->resolve_names( $type );
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
    if (defined $shortcut and $shortcut){
        if (ref $type eq $btclass){
            return "shortcut '$shortcut' is alreadey used by another basic type" if exists $self->{'basic_shortcut'}{$shortcut};
            $self->{'basic_shortcut'}{$shortcut} = $type->name;
        } else {
            return "shortcut '$shortcut' is alreadey used by another basic type" if exists $self->{'param_shortcut'}{$shortcut};
        }

    }
    unless (defined $public and $public){
        my ($package, $file, $line) = caller();

    }
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
sub get_type {                                 # ~type -- ~param       --> .btype|.ptype|undef
    my ($self, $type_name, $param_name) = @_;
    ($type_name, $param_name) = @$type_name if ref $type_name eq 'ARRAY';
    if (defined $param_name){
       return $self->{'param_type'}{$type_name}{$param_name} if exists $self->{'param_type'}{$type_name}
    } else { return $self->{'basic_type'}{$type_name}  }
    undef;
}
sub is_type_known { ref get_type(@_) ? 1 : 0 } #.tstore ~type - ~param --> ?
sub is_type_owned {                                 # .tstore ~type - ~param --> ?
    my ($type) = _get_type_def_(@_);
    return 0 unless ref $type;
    my ($package, $file, $line) = caller();
    if ($type->kind eq 'basic'){
        return ($self->{'basic_owner'}{$type->name} eq $package and $self->{'basic_origin'}{$type->name} eq $file) ? 1 : 0
    } else {
        return ($self->{'basic_owner'}{$type->name}{$type->parameter->name} eq $package 
                and $self->{'basic_origin'}{$type->name}{$type->parameter->name} eq $file) ? 1 : 0
    }
}
sub list_type_names   {                        # - ~kind ~ptype              --> @~btype|@~ptype|@~param
    my ($self, $kind, $type_name) = @_;        # kind = 'basic' | 'param'
    ($kind = _key_from_kind_($kind)) or return;
    if (defined $type_name){
        return unless exists $self->{'param_type'}{$type_name} and $kind eq 'param';
        return sort keys %{ $self->{'param_type'}{$type_name}};
    }
    sort keys %{$self->{$kind.'_type'}};
}
sub _key_from_kind_ {
    return 'basic' if not defined $_[0] or index($_[0], 'bas') > -1;
    return 'param' if index($_[0], 'para') > -1;
}
#### type symbols ##############################################################
sub list_symbols    {                        #                             --> @~symbols
    my ($self, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    sort keys( %{$self->{$kind.'_symbol'}});
}
sub type_name_from_symbols  {                        # ~kind ~shortcut      --> ~type|undef
    my ($self, $shortcut, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    $self->{$kind.'_symbol'}{$shortcut};
}
sub list_forbidden_symbols { sort keys %{$_[0]->{'forbid_symbol'}} }  # .tstore     --> @~symbols
sub allow_symbols  {                        # .tstore @~shortcut          --> ~errormsg
    my ($self) = shift;
    return 'can not change a closed type store' unless $self->{'open'};
    map {delete $self->{'forbid_symbol'}{$_}} grep {exists $self->{'forbid_symbol'}{$_}} @_;
}
sub forbid_symbols  {                        # .tstore @~shortcut          --> ~errormsg
    my ($self) = shift;
    return 'can not change a closed type store' unless $self->{'open'};
    map {$self->{'forbid_symbol'}{$_}++} grep {not exists $self->{'forbid_symbol'}{$_}} grep { _is_symbol($_) } @_;
}
sub _check_symbol {
    my ($self, $short, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    return "type symbol is undefined" unless defined $_[0];
    return "type symbol $_[0] has to be one none id char (not a-z0-9_)" unless _is_symbol($_[0]);
    return "type symbol $_[0] is not allowed" if exists $self->{'forbid_symbol'}{$_[0]};
    return "$kind type symbol $_[0] is already taked allowed" if exists $self->{$kind.'_symbol'}{$_[0]};
    '';
}
sub _is_symbol {length $_[0] == 1 and $_[0] !~ /[a-z0-9_]/ }
################################################################################
3;
__END__


use v5.20;
use warnings;

# extendable collection of simple and parametric type objects with symbol, dependency and ownership resolver
#       multiple parametric types with same name and different parameters must have same owner and shortcut
#       open stores ($self->{open} eq 'open') cannot be closed (like normal == 0 | 1 = ?) 

package Kephra::Base::Data::Type::Namespace;
our $VERSION = 0.13;
use Kephra::Base::Data::Type::Basic;             my $btclass = 'Kephra::Base::Data::Type::Basic';
use Kephra::Base::Data::Type::Parametric;        my $ptclass = 'Kephra::Base::Data::Type::Parametric';
#### constructor, serialisation ################################################
sub new {      # -- |'open'   --> .tnamespace
    my ($pkg) = @_;                      #  0|1|'open' (stay)    __PACKAGE__  __FILE__
    bless {basic_type => {}, param_type => {}, open => (exists $_[1] and lc $_[1] eq 'open') ? 'open' : 1, 
           basic_owner => {}, param_owner => {}, basic_origin => {}, param_origin => {},
           basic_symbol => {}, basic_symbol_name => {}, param_symbol => {}, param_symbol_name => {}, forbid_symbol => {}};
}
sub state {    #            --> %state
    my ($self) = @_;
    my %state = (basic_owner => {%{$self->{'basic_owner'}}}, basic_origin => {%{$self->{'basic_origin'}}}, 
                 basic_symbol => {%{$self->{'basic_symbol'}}},  param_symbol => {%{$self->{'param_symbol'}}},
                 forbid_symbol => [@{$self->{'forbid_symbol'}}],  open => $self->{'open'}  );
    $state{'basic_type'}{$_->name} = $_->state for values %{$self->{'basic_type'}};
    for my $type_name (keys %{$self->{'param_type'}}) {
        $state{'param_type'}{$type_name}{$_->parameter->name} = $_->state for values %{$self->{'param_type'}{$type_name}};
        $state{'param_owner'}{$type_name} = {%{$self->{'param_owner'}{$type_name}}} if exists $self->{'param_owner'}{$type_name};
        $state{'param_origin'}{$type_name} = {%{$self->{'param_origin'}{$type_name}}} if exists $self->{'param_origin'}{$type_name};
    }
    \%state;
}
sub restate {  # %state     --> .tnamespace
    my ($pkg, $state) = @_;
    return unless ref $state eq 'HASH' and ref $state->{'basic_type'} eq 'HASH' and ref $state->{'param_type'} eq 'HASH';
    $state->{'basic_type'}{$_->{'name'}} = Kephra::Base::Data::Type::Basic->restate($_) for values %{ $state->{'basic_type'} };
    $state->{'basic_symbol_name'}{ $state->{'basic_symbol'}{$_} } = $_ for keys %{$state->{'basic_symbol'}};
    $state->{'param_symbol_name'}{ $state->{'basic_symbol'}{$_} } = $_ for keys %{$state->{'param_symbol'}};
    for my $type_name (keys %{$state->{'param_type'}}) {
        $state->{'param_type'}{$type_name}{$_->{'parameter'}{'name'}} = Kephra::Base::Data::Type::Parametric->restate($_)
            for values %{$state->{'param_type'}{$type_name}};
    }
    bless $state;
}

################################################################################
sub is_open{ $_[0]->{'open'} ? 1 : 0 } # (open store cant be closed)                  # --> ?
sub close  { return 0 if $_[0]->{'open'} eq 'open' or not $_[0]->{'open'}; $_[0]->{'open'} = 0; 1 } # --> ?

##### type definition handling (resolving type names) ##########################
sub _root_parent_ID {
    my ($type_def) = @_;
    return unless defined $type_def;
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' and exists $type_def->{'parent'};
    return $type_def if ref $type_def eq 'ARRAY' or (not ref $type_def and $type_def);
}
sub _root_parameter_ID {
    my ($type_def) = @_;
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' 
                                        and exists $type_def->{'parent'} and not exists $type_def->{'parameter'};
    _root_parent_ID( $type_def->{'parameter'} ) if ref $type_def eq 'HASH' and exists $type_def->{'parameter'};
}
sub _solve_ID { _root_parent_ID($_[0]), _root_parameter_ID($_[0]) }
sub need_resolve { grep {$_}                 _solve_ID($_[1]) }  # _ .typedef -->  @ID (0-2)
sub can_resolve { grep {$_[0]->get_type($_)} _solve_ID($_[1]) }  # _ .typedef -->  @ID (0-2)
sub resolve_names {                                              # _          --> +known, +solved
    my ($self, $type_def) = @_;
    return undef unless ref $type_def eq 'HASH';
    my $rparent = my $rparameter = $type_def;
    my ($known, $open) = (0,0);
    $rparent = $rparent->{'parent'} while ref $rparent->{'parent'} eq 'HASH';
    if (exists $rparent->{'parent'} and (not ref $rparent->{'parent'} or ref $rparent->{'parent'} eq 'ARRAY')){
        my $type = $self->get_type( $rparent->{'parent'} );
        if (ref $type){ $rparent->{'parent'} = $type; $known++ } else { $open++ }
    }
    $rparameter = $rparameter->{'parent'} while ref $rparameter->{'parent'} eq 'HASH'
                                            and not exists $rparameter->{'parameter'};

    if (ref $rparameter->{'parameter'} eq 'HASH'){
        $rparameter = $rparameter->{'parameter'};
        $rparameter = $rparameter->{'parent'} while ref $rparameter->{'parent'} eq 'HASH';
        return $known, $open if ref $rparameter->{'parent'} or not exists $rparameter->{'parent'}; 
        my $type = $self->get_type( $rparameter->{'parent'} );
        if (ref $type){ $rparameter->{'parent'} = $type; $known++ } else { $open++ }
    } elsif (exists $rparameter->{'parameter'} and not ref $rparameter->{'parameter'}){
        my $type = $self->get_type( $rparameter->{'parameter'} );
        if (ref $type){ $rparameter->{'parameter'} = $type; $known++ } else { $open++ }
    }
    $known, $open;
}
sub create_type {                                 # %typedef --> .type 
    my ($self, $type_def) = @_;
    return undef unless ref $type_def eq 'HASH';
    my ($known, $open) = $self->resolve_names($type_def);
    return "definition of type '$type_def->{name}' refers to unknown types" if $open;
    (exists $type_def->{'parameter'} or ref $type_def->{'parent'} eq $ptclass)
          ? Kephra::Base::Data::Type::Parametric->new( $type_def )
          : Kephra::Base::Data::Type::Basic->new( $type_def );
}

#### type handling (add remove lookup) ########################################
sub add_type {                               # .type - ~symbol ?public      --> .type, @ID | ~!
    my ($self, $type, $symbol, $public) = @_;
    return 'can not add to a closed type namespace' unless $self->{'open'};
    my ($package, $file, $line) = (defined $public and $public) ? ('', '', '') : caller();
    my $type_ref = ref $type;
    if ($type_ref eq 'HASH'){
        for my $tname( $self->need_resolve( $type )) {
            return "definition of type $type->{name} refers to unknown type '$tname'" unless ref $self->get_type( $tname );
        }
        $self->_add_type_def( $type, $symbol, $package, $file );
    } elsif ($type_ref eq $btclass or $type_ref eq $ptclass) {
        $self->_add_type_object( $type, $symbol, $package, $file );
    } else { "this namespace accepts only type objects or type definitions (hash ref)" }
}
sub _add_type_def {
    my ($self, $type_def, $symbol, $package, $file ) = @_;
    my ($name, @added_names);
    return unless ref $type_def eq 'HASH';
    if (ref $type_def->{'parameter'} eq 'HASH'){
        my @result = $self->_add_type_def( $type_def->{'parameter'}, undef, $package, $file);
        return @result unless ref $result[0];
        $type_def->{'parameter'} = shift @result;
        push @added_names, @result;
    } elsif (exists $type_def->{'parameter'} and not ref $type_def->{'parameter'}){
        my $ptype = $self->get_type( $type_def->{'parameter'} );
        return "definition of type '$type_def->{name}' has issue: parameter name '$type_def->{'parameter'}' refers to unknow type"
            unless ref $ptype;
        $type_def->{'parameter'} = $ptype;
    }
    if (ref $type_def->{'parent'}  eq 'HASH'){
        my @result = $self->_add_type_def( $type_def->{'parent'}, undef, $package, $file);
        return @result unless ref $result[0];
        $type_def->{'parent'} = shift @result;
        push @added_names, @result;
    } elsif (exists $type_def->{'parent'} and (not ref $type_def->{'parent'} or ref  $type_def->{'parent'} eq 'ARRAY')){
        my $ptype = $self->get_type( $type_def->{'parent'} );
        return "definition of type '$type_def->{name}' has issue: parent name '$type_def->{'parent'}' refers to unknow type"
            unless ref $ptype;
        $type_def->{'parent'} = $ptype;
    }
    $symbol = delete $type_def->{'symbol'} unless defined $symbol;

    my $type = (exists $type_def->{'parameter'} or ref $type_def->{'parent'} eq $ptclass)
          ? Kephra::Base::Data::Type::Parametric->new( $type_def )
          : Kephra::Base::Data::Type::Basic->new( $type_def );
    ($type, $name) = $self->_add_type_object( $type, $symbol, $package, $file );
     return $type unless ref $type;
    $type, $type->ID, @added_names;
}
sub _add_type_object {
    my ($self, $type, $symbol, $package, $file) = @_;
    if (defined $symbol and $symbol){
         my $error = $self->_check_symbol( $symbol , $type->kind );
         return $error if $error;
    } else { $symbol = '' }
    my $type_name = $type->name;
    if (ref $type eq $btclass){ # basic types
        return "there is alreasy a basic type under the name '$type_name' in this namespace" if exists $self->{'basic_type'}{ $type_name};
        $self->{'basic_type'}{ $type_name} = $type;
        $self->{'basic_owner'}{ $type_name } = $package if $package;
        $self->{'basic_origin'}{ $type_name } = $file if $file;
        $self->{'basic_symbol'}{ $type_name } = $symbol if $symbol;
        $self->{'basic_symbol_name'}{ $symbol } = $type_name if $symbol;
        return $type, $type_name;
    } elsif (ref $type eq $ptclass) { # param types
        my $param_name = $type->parameter->name;
        my $full_name = $type_name.' of '.$param_name;
        return "there is alreasy a parametric type under the name '$full_name' in this namespace" 
            if exists $self->{'param_type'}{ $type_name}{ $param_name };
        $self->{'param_type'}{ $type_name}{ $param_name } = $type;
        $self->{'param_owner'}{ $type_name }{ $param_name } = $package if $package;
        $self->{'param_origin'}{ $type_name }{ $param_name } = $file if $file;
        if ($symbol and not exists $self->{'param_symbol'}{ $type_name }){
            $self->{'param_symbol'}{ $type_name } = $symbol;
            $self->{'param_symbol_name'}{ $symbol } = $type_name;
        }
        return $type, [$type_name, $param_name];
    }
}

sub remove_type {                          # ~type - ~param                  --> .type|~!
    my $self = shift;
    return 'can not remove from a closed type namespace' unless $self->{'open'};
    my $type = $self->get_type( @_ );
    my $full_name = $type->full_name;
    return "type '$full_name' is unknown and can not be removed from namespace" unless ref $type;
    my ($package, $file, $line) = caller();
    my $owned = $self->_is_type_owned($type, $package, $file);
    return "type '$full_name' can not be deleted by caller '$package' in '$file', because it is no the owner" unless $owned;
    my $type_name = $type->name;
    if ($type->kind eq 'basic') {
        delete $self->{'basic_symbol_name'}{ delete $self->{'basic_symbol'}{ $type_name } } if exists $self->{'basic_symbol'}{ $type_name };
        delete $self->{'basic_origin'}{ $type_name };
        delete $self->{'basic_owner'}{ $type_name };
        delete $self->{'basic_type'}{ $type_name };
    } else {  
        my $param_name = $type->parameter->name;
        my $type = delete $self->{'param_type'}{ $type_name }{ $param_name };
        delete $self->{'param_type'}{ $type_name } unless %{$self->{'param_type'}{ $type_name }};
        if (exists $self->{'param_symbol'}{ $type_name } and not exists $self->{'param_type'}{ $type_name }){
            delete $self->{'param_symbol_name'}{ delete $self->{'param_symbol'}{ $type_name } };
        }
        delete $self->{'param_origin'}{ $type_name }{ $param_name } if exists $self->{'param_origin'}{ $type_name };
        delete $self->{'param_origin'}{ $type_name }                unless %{$self->{'param_origin'}{ $type_name }};
        delete $self->{'param_owner'}{ $type_name }{ $param_name } if exists $self->{'param_owner'}{ $type_name };
        delete $self->{'param_owner'}{ $type_name }                unless %{$self->{'param_owner'}{ $type_name }};
    }
    $type;
}

sub get_type {                                 # ~type -- ~param       --> .btype|.ptype|undef
    my ($self, $type_name, $param_name) = @_;
    ($type_name, $param_name) = @$type_name if ref $type_name eq 'ARRAY';
    if (defined $param_name and $param_name){
       return $self->{'param_type'}{$type_name}{$param_name} if exists $self->{'param_type'}{$type_name}
    } elsif (defined $type_name) {
       return $self->{'basic_type'}{$type_name}  
    }
    undef;
}
sub has_type      { ref get_type(@_) ? 1 : 0 }      #.tnamespace ~type - ~param --> ?
sub is_type_owned {                                 # .tnamespace ~type - ~param --> ?
    my $self = shift;
    my $type = $self->get_type(@_);
    return 0 unless ref $type;
    my ($package, $file, $line) = caller();
    $self->_is_type_owned( $type, $package, $file );
}
sub _is_type_owned {
    my ($self, $type, $package, $file) = @_;
    if ($type->kind eq 'basic'){
        return 1 if not exists $self->{'basic_owner'}{$type->name};
        return 1 if $self->{'basic_owner'}{$type->name} eq $package and $self->{'basic_origin'}{$type->name} eq $file;
    } else {
        return 1 if not exists $self->{'param_owner'}{$type->name}
                 or not exists $self->{'param_owner'}{$type->name}{$type->parameter->name};
        return 1 if $self->{'param_owner'}{$type->name}{$type->parameter->name} eq $package 
                and $self->{'param_origin'}{$type->name}{$type->parameter->name} eq $file;
    }
    0;
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
sub list_symbols    {                                # _                     --> @~symbols
    my ($self, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    sort keys( %{$self->{$kind.'_symbol_name'}});
}
sub type_name_from_symbol {                          # ~symbolt -- ~kind     --> ~name|undef
    my ($self, $symbol, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    $self->{$kind.'_symbol_name'}{$symbol};
}
sub type_symbol_from_name {                          # ~name --  ~kind       --> ~symbol|undef
    my ($self, $name, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    $self->{$kind.'_symbol'}{$name};
}
sub list_forbidden_symbols { sort keys %{$_[0]->{'forbid_symbol'}} }     # _ --> @~symbols
sub allow_symbols  {                                 # _ @~shortcut          --> ~errormsg
    my ($self) = shift;
    return 'can not change a closed type namespace' unless $self->{'open'};
    map {delete $self->{'forbid_symbol'}{$_}} grep {exists $self->{'forbid_symbol'}{$_}} @_;
}
sub forbid_symbols  {                                # _ @~shortcut          --> ~errormsg
    my ($self) = shift;
    return 'can not change a closed type namespace' unless $self->{'open'};
    map {$self->{'forbid_symbol'}{$_}++} grep {not exists $self->{'forbid_symbol'}{$_}} grep { _is_symbol($_) } @_;
}
sub _check_symbol {
    my ($self, $symbol, $kind) = @_;
    ($kind = _key_from_kind_($kind)) or return;
    return "type symbol is undefined" unless defined $symbol;
    return "type symbol '$symbol' is not allowed (check list_forbidden_symbols)" if exists $self->{'forbid_symbol'}{$symbol};
    return "type symbol '$symbol' has to be one none id char (not a-z0-9_)" unless _is_symbol($symbol);
    return "$kind type symbol '$symbol' is already taked" if exists $self->{$kind.'_symbol_name'}{$symbol};
    '';
}
sub _is_symbol {length $_[0] == 1 and $_[0] !~ /[a-z0-9_]/ }

3;

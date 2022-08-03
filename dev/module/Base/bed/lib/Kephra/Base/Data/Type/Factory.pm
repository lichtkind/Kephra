use v5.18;
use warnings;

# utils for type object creation: checking, deps resolve, ID conversion

package Kephra::Base::Data::Type::Factory;
our $VERSION = 0.1;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;

use Exporter 'import';
our @EXPORT_OK = qw/is_type_ID is_type open_type_ID/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $btclass = 'Kephra::Base::Data::Type::Basic';
my $ptclass = 'Kephra::Base::Data::Type::Parametric';
my %type_class = (basic => $btclass, param => $ptclass);
my %class_type = ($btclass => 'basic', $ptclass => 'param');
my @type_kinds = keys %type_class;
my @type_class_names = values %type_class;

##### main function & helper ###################################################

sub create_type {
    my $tdef = shift;
    return "type definitions have to be a HASH ref" unless ref $tdef eq 'HASH';
}

sub root_parent_ID {
    my ($type_def) = @_;
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' and exists $type_def->{'parent'};
    return $type_def if is_type_ID( $type_def );
}
sub root_parameter_ID {
    my ($type_def) = @_;
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' and exists $type_def->{'parent'}
                                                                    and not exists $type_def->{'parameter'};
    return unless ref $type_def eq 'HASH' and exists $type_def->{'parameter'};
    $type_def = $type_def->{'parameter'};
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' and exists $type_def->{'parent'};
    return $type_def if is_type_ID( $type_def );
}
sub open_type_IDs { grep {$_} root_parent_ID($_[0]), root_parameter_ID($_[0]) }

##### ID checker and converter #################################################

sub base_name_from_ID        {} # $typeID    --> ~name
sub param_name_from_ID       {} # $typeID    --> ~name
sub full_name_from_ID        {} # $typeID    --> ~full_name 
sub ID_from_full_name        {} # ~full_name --> $typeID

sub is_type_ID               {} # $typeID    --> ?
sub type_ID_kind             {} # $typeID    --> ( 'basic' | 'param' | '' )

##### type def checker #########################################################

sub is_type_def              {} # %Tdef      --> ?
sub is_basic_type_def        {} # %Tdef      --> ?
sub is_param_type_def        {} # %Tdef      --> ?
sub type_def_kind            {
    my $def = shift;
    return unless ref $def eq 'HASH';
} # %Tdef      --> ( 'basic' | 'param' | '' )
 
##### type object checker #######################################################

sub is_type                  { exists $class_type{ ref $_[0] } }
sub is_basic_type            { ref $_[0] eq $%type_class{'basic'} }
sub is_param_type            { ref $_[0] eq $%type_class{'param'} }
sub type_kind                { $class_type{ ref $_[0] } }

4;

__END__

ID str = simple
   ARRAY = parametric

sub resolve_type_ref {                                                          # _ .typedef --> +known, +solved
    my ($self, $type_def) = @_;
    return undef unless ref $type_def eq 'HASH';
    my @need = open_type_ID( $type_def );
    return (0,0) unless @need;
    my @have = grep {$_} map { $self->get_type($_) } @need;
    return (int @have, @need - @have) unless @need == @have;
    my %dict = map {Kephra::Base::Data::Type::Factory::full_name_from_ID( $need[$_] ), $have[$_]} 0 .. $#have;
    Kephra::Base::Data::Type::Factory::resolve_type_ref( $type_def, \%dict );
   (int @have, int @need );
}

sub create_type {                                 # %typedef --> .type 
    my ($self, $type_def) = @_;
    return undef unless ref $type_def eq 'HASH';
    my ($known, $open) = $self->resolve_type_ref( $type_def );
    return "definition of type '$type_def->{name}' refers to unknown types, by name resolved $known" if $open;
    Kephra::Base::Data::Type::Factory::_create_type($type_def);
}

#### type handling (add remove lookup) ########################################
sub add_type {                               # .type - ~symbol ?public      --> .type, @ID | ~!
    my ($self, $type, $symbol, $public) = @_;
    return 'can not add to a closed type namespace' unless $self->{'open'};
    my ($package, $file, $line) = (defined $public and $public) ? ('', '', '') : caller();
    if (ref $type eq 'HASH'){
        for my $tname( $self->need_resolve( $type )) {
            return "definition of type $type->{name} refers to unknown type '$tname'" unless ref $self->get_type( $tname );
        }
        $self->_add_type_def( $type, $symbol, $package, $file );
    } elsif ( is_type($type) ) {
        $self->_add_type_object( $type, $symbol, $package, $file );
    } else { "this namespace accepts only type objects or type definitions (hash ref)" }
}
sub _add_type_def {
    my ($self, $type_def, $symbol, $package, $file ) = @_;
    my ($name, @added_ID);
    return unless ref $type_def eq 'HASH';
    if (ref $type_def->{'parameter'} eq 'HASH'){
        my @result = $self->_add_type_def( $type_def->{'parameter'}, undef, $package, $file);
        return @result unless ref $result[0];
        $type_def->{'parameter'} = shift @result;
        push @added_ID, @result;
    } elsif (exists $type_def->{'parameter'} ){
        my $ptype = $self->get_type( $type_def->{'parameter'} );
        return "definition of type '$type_def->{name}' has issue: parameter name '$type_def->{'parameter'}' refers to unknow type"
            unless ref $ptype;
        $type_def->{'parameter'} = $ptype;
    }
    if (ref $type_def->{'parent'}  eq 'HASH'){
        my @result = $self->_add_type_def( $type_def->{'parent'}, undef, $package, $file);
        return @result unless ref $result[0];
        $type_def->{'parent'} = shift @result;
        push @added_ID, @result;
    } elsif (exists $type_def->{'parent'}){
        my $ptype = $self->get_type( $type_def->{'parent'} );
        return "definition of type '$type_def->{name}' has issue: parent name '$type_def->{'parent'}' refers to unknow type"
            unless ref $ptype;
        $type_def->{'parent'} = $ptype;
    }
    $symbol = delete $type_def->{'symbol'} unless defined $symbol;

    my $type = Kephra::Base::Data::Type::Factory::_create_type($type_def);
    return $type unless ref $type;
    ($type, $name) = $self->_add_type_object( $type, $symbol, $package, $file );
    return $type unless ref $type;
    $type, $type->ID, @added_ID;
}



sub create_type              {} # $Tdef      --> @[full_name => .T, ..] .T =^ (basic | param)
                                #                $.T                       =^ (type object)

sub root_parent_ID           {} # %Tdef      --> undef | typeID
sub root_parameter_ID        {} # %Tdef      --> undef | typeID
sub open_type_IDs            {} # %Tdef      --> undef | typeID [1..2]

sub base_name_from_ID        {} # $typeID    --> ~name
sub param_name_from_ID       {} # $typeID    --> ~name
sub full_name_from_ID        {} # $typeID    --> ~full_name 
sub ID_from_full_name        {} # ~full_name --> $typeID

sub is_type_ID               {} # $typeID    --> ?
sub type_ID_kind             {} # $typeID    --> ( 'basic' | 'param' | '' )

sub is_type_def              {} # %Tdef      --> ?
sub is_basic_type_def        {} # %Tdef      --> ?
sub is_param_type_def        {} # %Tdef      --> ?
sub type_def_kind            {} # %Tdef      --> ( 'basic' | 'param' | '' )
 
sub is_type                  {} # .T         --> ?
sub is_basic_type            {} # .T         --> ?
sub is_param_type            {} # .T         --> ?
sub type_kind                {} # .T         --> ( 'basic' | 'param' | '' )


sub is_type_object {                              # .type  --  ~kind = 'basic'|'param' --> ?
    my $ref = shift;
    if (defined $_[0]){
       (exists $type_class{$_[0]} and ref $ref eq $type_class{$_[0]}) ? 1 : 0;
    }
    for (@type_class_names){ return 1 if ref $ref eq $_ } 0;
}

sub is_type_kind {                              # ~kind  --> ?
    my $ref = shift;
    if (defined $_[0]){
       (exists $type_class{$_[0]} and ref $ref eq $type_class{$_[0]}) ? 1 : 0;
    }
    for (@type_class_names){ return 1 if ref $ref eq $_ } 0;
}

sub is_type_ID {                          # $val                     --> ?
    return 0 unless defined $_[0] and $_[0];
    return 1 if not ref $_[0];
    (ref $_[0] eq 'ARRAY' and @{$_[0]} == 2) ? 1 : 0;
}

sub full_name_from_ID {                          # $val                     --> ?
    return undef unless defined $_[0] and $_[0];
    return $_[0] if not ref $_[0];
    (ref $_[0] eq 'ARRAY' and @{$_[0]} == 2) ? $_[0][0].' of '.$_[0][1] : undef;
}

##### check dependencies #######################################################



sub resolve_type_ref { 
    my ($type_def, $dict) = @_;
    return 0 unless ref $type_def eq 'HASH' and ref $dict eq 'HASH';
    my $para_def = my $parent_def = $type_def;
    $parent_def = $parent_def->{'parent'} while exists $parent_def->{'parent'} and ref $parent_def->{'parent'} eq 'HASH';
    my $res = 0;
    if (exists $parent_def->{'parent'}){
        my $full_name = full_name_from_ID($parent_def->{'parent'});
        return 0 unless exists $dict->{ $full_name };
        $parent_def->{'parent'} = $dict->{ $full_name };
        $res++;
    }
    $para_def = $para_def->{'parent'} while ref $para_def eq 'HASH' and exists $para_def->{'parent'}
                                                                    and not exists $para_def->{'parameter'};
    return unless exists $para_def->{'parameter'};
    if (ref $para_def->{'parameter'} eq 'HASH'){
        $para_def = $para_def->{'parameter'};
        $para_def = $para_def->{'parent'} while exists $para_def->{'parent'} and ref $para_def->{'parent'} eq 'HASH';
        return $res unless exists $para_def->{'parent'};
        my $full_name = full_name_from_ID( $para_def->{'parent'} );
        return $res unless exists $dict->{ $full_name };
        $para_def->{'parent'} = $dict->{ $full_name };
        $res++;
    } else {
        my $full_name = full_name_from_ID($parent_def->{'parameter'});
        return $res unless exists $dict->{ $full_name };
        $parent_def->{'parameter'} = $dict->{ $full_name };
        $res++;
    }
    $res; # how many type ID refs resolved
}

#sub split_definitions {     my ($type_def) = @_; }

sub create_type {                                 # %typedef --> .type 
    my ($type_def) = @_;
    return undef unless ref $type_def eq 'HASH';
    my ($open) = open_type_ID( $type_def );
    return "definition of type '$type_def->{name}' contains type names, which has to be resolved to objects" if $open;
    _create_type($type_def);
}
sub _create_type {
    my ($type_def) = @_;
    (exists $type_def->{'parameter'} or ref $type_def->{'parent'} eq $ptclass)
          ? Kephra::Base::Data::Type::Parametric->new( $type_def )
          : Kephra::Base::Data::Type::Basic->new( $type_def );
}

sub type_class_names { @type_class_names }
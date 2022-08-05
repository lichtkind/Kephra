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

sub create_type      {  # $Tdef      --> @[full_name => .T, ..] .T =^ (basic | param)
    my $Tdef = shift;
    return "type definitions have to be a HASH ref" unless ref $Tdef eq 'HASH';
    (is_param_type_def($Tdef)) ? Kephra::Base::Data::Type::Parametric->new($Tdef) 
                               : Kephra::Base::Data::Type::Basic->new($Tdef);
}

sub create_type_chain {  # $Tdef      --> @[full_name => .T, ..] .T =^ (basic | param)
    my $Tdef = shift;
    return "type definitions have to be a HASH ref" unless ref $Tdef eq 'HASH';
    my $open = get_open_IDs($Tdef);
    return $open if %$open;
    my @ret = _create_type_chain( $Tdef );
    wantarray ? @ret : $ret[-1];
}
sub _create_type_chain       {
    my $Tdef = shift;
    my @ret;
    if (ref $Tdef->{'parent'} eq 'HASH'){
        my @Tobj = _create_type_chain( $Tdef->{'parent'} );
        return @Tobj if @Tobj == 1;
        push @ret, @Tobj;
        $Tdef->{'parent'} = $Tobj[-1];
    }
    if (ref $Tdef->{'parameter'} eq 'HASH'){
        my @Tobj = _create_type_chain( $Tdef->{'parameter'} );
        return @Tobj if @Tobj == 1;
        push @ret, @Tobj;
        $Tdef->{'parameter'} = $Tobj[-1];
    }
    my $Tobj = create_type($Tdef);
    return $Tobj unless ref $Tobj;
    push @ret, $Tobj->full_name, $Tobj;
    @ret;
}
sub get_open_IDs             { # %Tdef      --> %open
    my $Tdef = shift;
    return {} unless ref $Tdef eq 'HASH';
    my $open = {};
    my @parent_ID = root_parent_ID( $Tdef );
    if (@parent_ID) {
      $open->{'parent_ID'} = $parent_ID[0];
      $open->{'parent_ref'} = $parent_ID[1];
    }
    my @param_ID = root_parameter_ID( $Tdef );
    if (@param_ID) {
      $open->{'param_ID'} = $param_ID[0];
      $open->{'param_ref'} = $param_ID[1];
    }
    $open;
}
sub root_parent_ID           { # %Tdef      --> - typeID, %Tdef
    my ($type_def) = @_;
    return if ref $type_def ne 'HASH';
    $type_def = $type_def->{'parent'} while ref $type_def->{'parent'} eq 'HASH';
    return $type_def->{'parent'}, $type_def if is_type_ID( $type_def->{'parent'} );
}
sub root_parameter_ID        { # %Tdef      --> - typeID, %Tdef
    my ($type_def) = @_;
    return if ref $type_def ne 'HASH';
    $type_def = $type_def->{'parent'} while ref $type_def->{'parent'} eq 'HASH' 
                                        and not exists $type_def->{'parameter'};
    return unless exists $type_def->{'parameter'};
    return $type_def->{'parameter'}, $type_def if is_type_ID( $type_def->{'parameter'} );

    $type_def = $type_def->{'parameter'} if ref $type_def->{'parameter'} eq 'HASH';
    $type_def = $type_def->{'parent'} while ref $type_def->{'parent'} eq 'HASH';
    return $type_def->{'parent'}, $type_def if is_type_ID( $type_def->{'parent'} );
}

sub resolve_open_ID        { # %open      --> ?
    my ($open) = @_;
    return 0 unless ref $open eq 'HASH';
    if (ref $open->{'parent_ref'} eq 'HASH' 
    and (ref $open->{'parent'} eq 'HASH') or is_type($open->{'parent'})) {
        $open->{'parent_ref'}{'parent'} = $open->{'parent'};
        delete $open->{'parent'};
        delete $open->{'parent_ID'};
        delete $open->{'parent_ref'};
    }
    if (ref $open->{'param_ref'} eq 'HASH'
    and (ref $open->{'param'} eq 'HASH') or is_type($open->{'param'})) {
        $open->{'param_ref'}{'parent'} = $open->{'param'};
        delete $open->{'param'};
        delete $open->{'param_ID'};
        delete $open->{'param_ref'};
    }
    (%$open) ? 1 : 0;
}

##### ID checker and converter #################################################

sub base_name_from_ID        { # $typeID     --> ~name
    return '' unless defined $_[0];
    return $_[0] unless ref $_[0];
    (ref $_[0] eq 'ARRAY' and @{$_[0]} == 2) ? $_[0][0] : '';

}
sub param_name_from_ID       { # $typeID     --> ~name
    (ref $_[0] eq 'ARRAY' and @{$_[0]} == 2) ? $_[0][1] : '';
}
sub full_name_from_ID        { # $typeID     --> ~full_name 
    return '' unless defined $_[0];
    return $_[0] unless ref $_[0];
    (ref $_[0] eq 'ARRAY' and @{$_[0]} == 2) ? $_[0][1].' of '.$_[0][1] : '';
}
sub ID_from_full_name        { # ~full_name  --> $typeID
    return '' unless defined $_[0] and not ref $_[0] and $_[0];
    my @parts = split / of /, shift;
    (@parts == 1) ? $_[0] : (@parts == 2) ? \@parts : '';
}

sub is_type_ID               { # $typeID     --> ?
    return 0 unless defined $_[0];
    return 1 if ref $_[0] eq 'ARRAY' and @{$_[0]} == 2;
    (not ref $_[0] and $_[0]) ? 1 : 0;
}
sub type_ID_kind             { # $typeID     --> ( 'basic' | 'param' | '' )
    return '' unless defined $_[0];
    return 'param' if ref $_[0] eq 'ARRAY' and @{$_[0]} == 2;
    (not ref $_[0] and $_[0]) ? 'basic' : '';

}

##### type def checker #########################################################

sub is_type_def              { # %Tdef       --> ?
    my $def = shift;
    return 0 unless ref $def eq 'HASH';
    return 0 unless exists $def->{'name'} and exists $def->{'help'};
}
sub is_basic_type_def        { # %Tdef       --> ?
    my $def = shift;
    return 0 unless ref $def eq 'HASH';
    return 0 unless exists $def->{'name'} and exists $def->{'help'};
    return 0 unless (exists $def->{'code'} and exists $def->{'default'})
                  or exists $def->{'parent'};
    1;
}
sub _has_parameter {
    exists $_[0]->{'parameter'} 
    or (ref $_[0]->{'parent'} eq 'HASH' and exists $_[0]->{'parent'}{'parameter'})
    or (ref $_[0]->{'parent'} eq $ptclass);
}
sub is_param_type_def        { # %Tdef       --> ?
    my $def = shift;
    return 0 unless is_basic_type_def($def);
    _has_parameter( $def ) ? 1 : 0;
}
sub type_def_kind            { # %Tdef       --> ( 'basic' | 'param' | '' )
    my $def = shift;
    return '' unless is_basic_type_def($def);
    _has_parameter( $def ) ? 'param' : 'basic';
}
 
##### type object checker #######################################################

sub is_type                  { exists $class_type{ ref $_[0] } }
sub is_basic_type            { ref $_[0] eq $type_class{'basic'} }
sub is_param_type            { ref $_[0] eq $type_class{'param'} }
sub type_kind                { $class_type{ ref $_[0] } }

4;

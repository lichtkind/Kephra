use v5.18;
use warnings;

# checking type definition , type objects and creating type objects from them definitions

package Kephra::Base::Data::Type::Factory;
our $VERSION = 0.20;
use Kephra::Base::Data::Type::Basic;
use Kephra::Base::Data::Type::Parametric;

use Exporter 'import';
our @EXPORT_OK = qw/is_type_ID is_type open_type_ID/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $btclass = 'Kephra::Base::Data::Type::Basic';
my $ptclass = 'Kephra::Base::Data::Type::Parametric';
my %type_class = (basic => $btclass, param => $ptclass);
my @type_kinds = keys %type_class;
my @type_class_names = values %type_class;

##### which kinds of types are there ###########################################
sub class_names { @type_class_names }
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

sub _root_parent_ID {
    my ($type_def) = @_;
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' and exists $type_def->{'parent'};
    return $type_def if is_type_ID( $type_def );
}
sub _root_parameter_ID {
    my ($type_def) = @_;
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' and exists $type_def->{'parent'}
                                                                    and not exists $type_def->{'parameter'};
    return unless ref $type_def eq 'HASH' and exists $type_def->{'parameter'};
    $type_def = $type_def->{'parameter'};
    $type_def = $type_def->{'parent'} while ref $type_def eq 'HASH' and exists $type_def->{'parent'};
    return $type_def if is_type_ID( $type_def );
}
sub open_type_ID { grep {$_} _root_parent_ID($_[0]), _root_parameter_ID($_[0]) }


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

4;

__END__

ID str = simple
   ARRAY = parametric
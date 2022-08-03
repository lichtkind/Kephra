use v5.20;
use warnings;

# holds one or several type stores, apply type checking

package Kephra::Base::Data::Type::Checker;
our $VERSION = 0.10;

use Kephra::Base::Data::Type::Standard;

#### constructor, serialisation ################################################
my $std_name = 'standard';
sub new {
    my ($pkg, $name, $first_set_name, $no_std) = @_;
    return "need a name as first argument" unless defined $name;
    my $self = {set_order => [], set => {}, open => $_[1]//1, name => $name };
        $self->{'set'}{$std_name} = Kephra::Base::Data::Type::Standard::set unless defined $no_std and $no_std;
    if (defined $name and $name) {
        return "set name can not be '$std_name'" if $name eq $std_name;
        $self->{'set'}{$name} = Kephra::Base::Data::Type::Set->new();
    }
    bless $self;
}

sub state {
    my ($self) = @_;
    my $state = { name => $self->{'name'}, set_order => [@{$self->{'set_order'}}],};
    $state->{'set'}{$_} = $self->{'set'}{$_}->state() for @{$self->{'set_order'}};
    $state;
}
sub restate {
    my ($pkg, $state) = @_;
    $state->{'set'}{$_} =  Kephra::Base::Data::Type::Set->restate( $state->{'set'}{$_} ) for @{$state->{'set_order'}};
    bless $state;
}

################################################################################
sub is_open {
    my ($self) = @_;
}
sub close {
    my ($self) = @_;
}
#### methods regarding type sets ###############################################

sub add_set{
    my ($self, $set_name, $set, $pos) = @_;           # _ ~name .set -- +pos --> .set
    $pos //= -1;
    return "need a name and type set as arguments" unless ref $set eq 'Kephra::Base::Data::Type::Set';
    return "'$set_name' is an already taken or invalid type set name" unless defined $set_name and $set_name 
           and $set_name ne $std_name and not exists $self->{'set'}{$set_name};
    my $nr = @{$self->{'set_order'}};
    return "'$pos' is an out of scope position sinthere are only $nr sets" if defined $pos and abs($pos) > $nr;
    splice @{$self->{'set_order'}}, $pos, 0, $set_name;
    $self->{'set'}{$set_name} = $set;
}

sub move_set {                                        # _ ~name +pos         --> .set
    my ($self, $set_name, $new_pos) = @_;
#    return 'can not remove from a closed type namespace' unless $self->{'open'};
    return "'$set_name' is not known by this type checker" unless defined $set_name and exists $self->{'set'}{$set_name};
    my $nr = @{$self->{'set_order'}};
    return "'$new_pos' is an out of scope position since there are only $nr sets" if defined $new_pos and abs($new_pos) >= $nr;
    my $old_pos = $self->_get_name_pos( $set_name );
    $new_pos-- if $new_pos > $old_pos;
    splice @{$self->{'set_order'}}, $old_pos, 1;
    splice @{$self->{'set_order'}}, $old_pos, 0, $set_name;
}

sub remove_set {                                      # _ ~name              --> .set
    my ($self, $set_name) = @_;
    return "'$set_name' is not known by this type checker" unless defined $set_name and exists $self->{'set'}{$set_name};
    @{$self->{'set_order'}} = grep {$_ ne $set_name} @{$_[0]->{'set_order'}};
    delete $self->{'set'}{$set_name};
}
sub get_type_set{ $_[0]->{'set'}{$_[1]} }
sub sets        { map {$_[0]->get_type_set($_)} $_[0]->set_names }
sub set_names    { @{$_[0]->{'set_order'}} }
sub _get_name_pos { grep { $_[0]->{'set_order'}[$_] eq $_[1]} 0 .. $#{$_[0]->{'set_order'}}}

##### methods regarding data types #############################################

sub get_type {                                     # _ ~type -- ~param       --> .btype|.ptype|undef
    my $self = shift; #my ($type_name, $param_name) = @_;
    for ($self->sets){
        my $t = $_->get_type( @_ );
        return $t if ref $t;
    }
}

sub list_types { map { $_->list_types(@_) } shift->sets }        # _         --> @(.btype|.ptype)
sub list_type_names { map { $_->list_type_names(@_) } shift->sets } # ~kind = 'basic' | 'param' -- ~param_type_name --> @~btype|@~ptype|@~param
sub list_type_symbols { map { $_->list_type_symbols(@_) } shift->sets } # -- ~kind = 'basic' | 'param' --> @~shortcut
sub check_data_against_type {                               # _ ~typeID $val              -->  ~errormsg
    my $self = shift;
    my $typeID = shift;
    my $type = $self->get_type( $typeID );
    unless (ref $type){
        my $type_name = ref $typeID eq 'ARRAY' ? $typeID->[0].' of '.$typeID->[1] : $typeID;
        return "no basic type named $type_name is known by this store" 
    }
    $type->check_data( @_ );
}

sub guess_basic_type {                     # .tstore $val                    --> @~type
    my ($self, $value) = @_;
    my @types = $self->list_type_names('basic');
    return undef unless @types; # gett passing types, most refined first
    map {$_->[0]} sort {$b->[1] <=> $a->[1]} map {[$_->[0], int @{$_->[1]->source}]}
        grep {not $_->[1]->check_data($value)} map {[$_, $self->get_type($_)]} @types;
}

7;

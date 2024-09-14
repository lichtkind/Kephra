use v5.18;
use warnings;

# central storage for all object refs (class instances, created by KBOS)
# Base::Class::* is namespace for self made aux classes 

package Kephra::Base::Class::Instance;
our $VERSION = 0.02;
use Kephra::Base::Class::Scope qw/cat_scope_path/;
use Kephra::Base::Class::Attribute;
use Kephra::Base::Class::Definition;

my %object = (); # register of all objects by class name
my %by_ref = (); # cross ref
my %parent = (); # ref to parent object

################################################################################
sub create {
    my ($class) = @_;
    return "can not create object of unknown class $class" unless Kephra::Base::Class::is_known($class);
    return "can not create object of class $class due unresolved dependencies" unless Kephra::Base::Class::resolve_deps($class);
    my $obj_refs = {};
    for (Kephra::Base::Class::Scope::main_list()){
        my $v = 0;
        $obj_refs->{$_} = bless(\$v, Kephra::Base::Class::Scope::name($_, $class));
    }
    push @{$object{$class}}, $obj_refs;
    $by_ref{int $_} = $obj_refs for values %$obj_refs;

    my $attribs = Kephra::Base::Class::Definition::get_attributes($class);
    $obj_refs->{attribute}{$_} = Kephra::Base::Class::Attribute::create
        ($class, $_, Kephra::Base::Class::get_types($class)->default_value( $attribs->{$_} )) for keys %$attribs;
    $by_ref{int $_} = $obj_refs for values %{$obj_refs->{attribute}};

    $attribs = Kephra::Base::Class::get_object_attributes($class);
    for (keys %$attribs){
        my $child = $obj_refs->{attribute}{$_} =
            Kephra::Base::Package::call_sub($attribs->{$_}->{class}.'::new',$attribs->{$_}->{class}, @{$attribs->{$_}->{new}});
        $parent{int $child} = $obj_refs;
    }

    $obj_refs->{class} = $class;
    $obj_refs->{public};
}

sub delete {
    my ($obj) = @_;
    return 0 unless ref $obj eq 'SCALAR' and exists $by_ref{int $obj};
    my $obj_refs = $by_ref{int $obj};

    delete $by_ref{int $_} for values %{$obj_refs->{attribute}};
    Kephra::Base::Class::Attribute::delete($_) for values %{$obj_refs->{attribute}};

    delete $by_ref{int $_} for values %{$obj_refs->{object_attribute}};
    my $attribs = Kephra::Base::Class::get_object_attributes( $obj_refs->{class} );
    for (keys %{$obj_refs->{object_attribute}}){
        Kephra::Base::Package::call_sub($attribs->{$_}->{class}.'::destroy', $obj_refs->{public}, @{$attribs->{$_}->{destroy}})
    }

    delete $by_ref{int $_} for values %$obj_refs;
    my $reflist = $object{ delete $obj_refs->{class} };
    for my $i (0..$#$reflist){
        splice(@$reflist, $i, $i+1) if $reflist->[$i] eq $obj_refs
    }
    1;
}
sub get_by_ref        { $by_ref{int $_[0]}                   if ref $_[0] }
sub get_public_self   { $by_ref{int $_[0]}{public}           if ref $_[0] and exists $by_ref{int $_[0]} }
sub get_private_self  { $by_ref{int $_[0]}{private}          if ref $_[0] and exists $by_ref{int $_[0]} }
sub get_access_self   { $by_ref{int $_[0]}{access}           if ref $_[0] and exists $by_ref{int $_[0]} }
sub get_attribute     { $by_ref{int $_[0]}{attribute}{$_[1]} if ref $_[0] and exists $by_ref{int $_[0]} }

################################################################################
1;

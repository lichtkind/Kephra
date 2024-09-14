use strict;
use v5.12;

package Kephra::App::Panel;
our @ISA = 'Wx::Panel';

use Kephra::API qw(is_widget is_sizer);
use Kephra::App::Sizer;


sub new {
	my $class = shift;
	my $parent = shift;
	$parent = Kephra::API::app_window() unless defined $parent and is_widget($parent);
	my $self = $class->SUPER::new( $parent, -1 );
	$self->{'sizer'} = Kephra::App::Sizer->new('vertical');
	$self->SetSizer( $self->{'sizer'}->bare_sizer );
	$self->append(@_);
	$self;
}

sub sizer { shift->{'sizer'} }

sub prepend         { shift->insert(  0, 0, @_ ) }
sub append          { shift->insert( -1, 0, @_ ) }
sub append_expanded { shift->insert( -1, 1, @_ ) }
sub insert_before   { my($self)=shift; $self->insert( $self->get_position(shift)  , 1, @_ ) }
sub insert_after    { my($self)=shift; $self->insert( $self->get_position(shift)+1, 1, @_ ) }
sub insert          { 
	my ($self) = shift; 
	my ($position) = shift;
	my ($proportion)  = shift;
	$self->adopt(@_);
	$self->sizer->insert($position, $proportion, @_);
	$self
}

sub adopt {
	my ($self) = shift;
	for my $item (@_) {
		$self->adopt( @$item ) if ref $item eq 'ARRAY';
		$item = $item->{'child'} if ref $item eq 'HASH';
		next unless is_widget($item);
		$item->Reparent($self) unless $item->GetParent eq $self;
	}
}

sub remove {}
sub detach {}
sub show {}
sub hide {}
sub all_widgets  {  }
sub child_by_nr  { $_[0]->sizer->child_widget($_[1]) }
sub get_position { $_[0]->sizer->get_position($_[1]) }

1;

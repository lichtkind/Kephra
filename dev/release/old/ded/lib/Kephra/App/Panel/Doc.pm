use v5.12;
use warnings;
use Wx;
use Kephra::App::Bar::Tab;

package Kephra::App::Panel::Doc;
our @ISA = 'Kephra::App::Panel';

our @splitter;
our @bar;
our $bar;

sub new {
	my( $class, $parent) = @_;
	my $self = $class->SUPER::new($parent);
	$splitter[1] = Kephra::App::Splitter->new($self);
	$bar = $bar[1] = Kephra::App::Bar::Tab->new($splitter[1]);
	$splitter[1]->set( {left => $bar });
	$self->append_expanded( $splitter[1] );
	$self;
}

1;

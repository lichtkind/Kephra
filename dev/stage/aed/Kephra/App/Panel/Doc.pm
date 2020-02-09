use v5.12;
use warnings;
use Wx;
use Kephra::App::Bar::Tab;

package Kephra::App::Panel::Doc;
our @ISA = 'Kephra::App::Panel';
our @splitter;
our @bar;
our $bar;

use Kephra::API  qw(app_window document);


sub new {
	my( $class, $parent) = @_;
	my $self = $class->SUPER::new($parent);
	$splitter[1] = Kephra::App::Splitter->new($self);
	$bar = $bar[1] = Kephra::App::Bar::Tab->new($splitter[1]);
	$splitter[1]->set( {left => $bar });
	$self->append_expanded( $splitter[1] );


	Wx::Event::EVT_AUINOTEBOOK_BEGIN_DRAG( $bar, $bar, sub {
		my ($bar, $event ) = @_;
		$bar->{'DND_page_nr'} = $event->GetSelection;
	});
	Wx::Event::EVT_AUINOTEBOOK_END_DRAG($bar, $bar, sub {
		my ($bar, $event ) = @_;
		return unless defined $bar->{'DND_page_nr'};
		$bar->move_page_position_visually($bar->{'DND_page_nr'}, $event->GetSelection);
		$bar->{'DND_page_nr'} = undef;
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED( $bar, $bar, sub {
		my ($bar, $event) = @_;
		$event->Skip if defined $event;
		return if $bar->{'construction'};
		my $new_page = $bar->GetPage( (defined $event) ? $event->GetSelection : $bar->GetSelection);
		my $doc = Kephra::Document::Stash::set_active_doc( $new_page );
		#focus ( $doc->{'active_editor'} );
		app_window()->default_title_update();
		app_window()->SetStatusText( $doc->{'syntaxmode'}, 1);
		app_window()->SetStatusText( $doc->{'encoding'}, 2);
		Wx::Window::SetFocus( $new_page );
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CLOSE( $bar, $bar, sub {
		my ($bar, $event ) = @_; 
		$event->Veto;
		document()->close();
	});# keep focus on editor even when klicking on tab bar


	$self;
}

1;

__END__
my $panel = $self->GetPage($position);
my $doc = Kephra::Document::Stash::set_active_doc( $panel );
focus ( $doc->{'active_editor'} );
app_window()->default_title_update();

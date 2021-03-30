use v5.12;
use warnings;

package Kephra::App::Window;
use base qw(Wx::Frame);

use Kephra::App::Dialog;
use Kephra::App::Editor;
BEGIN { say "--"; }
use Kephra::IO::LocalFile;
BEGIN { say "--"; }
our ($file, $encoding, $content, $ed);

sub new {
	my($class, $parent) = @_;
	my $self = $class->SUPER::new( undef, -1, '', [-1,-1], [1000,800] );
	$self->CreateStatusBar(3);
	$self->SetStatusWidths(100, 50, -1);
	$ed = Kephra::App::Editor->new($self, -1);
	Wx::Window::SetFocus( $ed );

	Wx::Event::EVT_KEY_DOWN($ed , sub {
		my ($ed, $event) = @_;
		my $code = $event->GetUnicodeKey;
		if   ($event->ControlDown and $code == ord('O')){ open_file( Kephra::App::Dialog::get_file_open() ) }
		elsif($event->ControlDown and $code == ord('Q')){ $self->Close }
		elsif($event->ControlDown and $code == ord('S')){
				Kephra::IO::LocalFile::write( $file, $encoding, $ed->GetText() );
				$ed->SetSavePoint;
		} 
		else { $event->Skip }
	});
	Wx::Event::EVT_STC_UPDATEUI($ed, -1, sub {
		$self->SetStatusText( $ed->GetCurrentPos, 0);
	});
	
	open_file(__FILE__);
	return $self;
}


sub open_file {
	my $candidate = shift;
	return unless $candidate and -r $candidate;
	($content, $encoding) = Kephra::IO::LocalFile::read( $file = $candidate );
	$ed->SetText( $content );
	$ed->EmptyUndoBuffer;
	$ed->SetSavePoint;
	$ed->GetParent->SetStatusText( $encoding, 1);
}

sub set_title {
	my ($self, $status) = @_;
	my $title = 'Single Edit - KephraCP stage 1 - ' . $file;
	$title .= ' *' if $status;
	$self->SetTitle($title);
}

1;
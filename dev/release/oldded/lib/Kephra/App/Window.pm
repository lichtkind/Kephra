use v5.12;
use warnings;

package Kephra::App::Window;

use base qw(Wx::Frame);
use Kephra::API qw(document is_document);
use Kephra::App::Dialog;
use Kephra::App::Splitter;
use Kephra::App::Panel;
use Kephra::App::Bar::Search;
use Kephra::App::Panel::Doc;


our ($docpanel, %splitter);

sub new {
	my($class, $parent) = @_;
	my $self = $class->SUPER::new( undef, -1, '', [-1,-1], [1000,800] );
	$self->CreateStatusBar(4);
	$self->SetStatusWidths(100, 60, 75, -1);

	$docpanel = Kephra::App::Panel::Doc->new($self);
	my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
	$sizer->Add( $docpanel,  1, &Wx::wxGROW);
	$self->SetSizer( $sizer );

	Wx::Event::EVT_CLOSE ($self,  sub { Kephra::App::shut_down() });
	return $self;
}

sub set_title {
	my ($self, $status) = @_;
	my $msg = $Kephra::NAME;
	$msg .= $status if defined $status;
	$self->SetTitle($msg);
}

sub default_title_update {
	my ($self) = @_;
	my $doc = document();
	return unless is_document($doc);
	my $msg = $doc->{'file_path'};
	$msg = $doc->{'title'} unless $msg;
	$msg .= '*' if $doc->{'editor'}->GetModify;
	$self->set_title($msg);
}


1;

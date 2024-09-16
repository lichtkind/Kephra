use v5.12;
use warnings;

package Kephra::App::Window;

use base qw(Wx::Frame);
use Kephra::API qw(document is_document);
use Kephra::App::DocBar;
use Kephra::App::Panel;

our ($docbar);

sub new {
	my($class, $parent) = @_;
	my $self = $class->SUPER::new( undef, -1, '', [-1,-1], [1000,800] );
	$self->CreateStatusBar(3);
	$self->SetStatusWidths(100, 75, -1);
	$docbar = Kephra::App::DocBar->new($self);

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

use v5.12;

use Wx;
use Wx::AUI;

package Kephra::App::DocBar;
our @ISA = 'Wx::AuiNotebook';

use Scalar::Util qw(blessed looks_like_number);
use Kephra::API  qw(:cmp app_window);
use Kephra::App::Editor;

sub new {
	my( $class, $parent) = @_;
	$parent = app_window() unless defined $parent;
	my $self = $class->SUPER::new( $parent, -1, [-1,-1], [-1,-1],
		&Wx::wxAUI_NB_TOP | &Wx::wxAUI_NB_TAB_MOVE | &Wx::wxAUI_NB_WINDOWLIST_BUTTON |
		&Wx::wxAUI_NB_SCROLL_BUTTONS | &Wx::wxAUI_NB_CLOSE_ON_ACTIVE_TAB
	);

	$self->{'visual_page_order'} = [];   # visual order of internal pos : vis -> int
	$self->{'internal_page_order'} = []; # internal order of visual pos : int -> vis

	#$_->add_instance($self) for Kephra::API::all_documents();
	$self->mount_events();
	$self;
}


sub add_page {
	my ($self, $new_page, $title, $position, $raise_focus) = @_;
	return warning( "DocBar pages need to be Kephra::App::Panel", 1 ) until is_panel($new_page);
	my $active_pos = $self->GetSelection;
	$title    = ''                           unless defined $title;
	$position = 'default'                    unless defined $position;
	$position = 'right'                      if $position eq 'default' or $position eq -1;
	$position = $self->rightmost_page_pos+1  if $position eq 'rightmost';
	$position = $active_pos + 1              if $position eq 'right';
	$position = $active_pos                  if $position eq 'left';
	$position = $self->leftmost_page_pos     if $position eq 'leftmost';
	$raise_focus = 0                         unless defined $raise_focus;

	$self->{'construction'} = 1;
	$new_page->Reparent($self);
	$self->InsertPage( $position, $new_page, $title, $raise_focus);
	#$self->set_page_title( $title, $new_page );
	app_window()->default_title_update();
	#focus($new_page) if $raise_focus;
	Wx::Window::SetFocus( $new_page ) if $raise_focus;

	# inserting new index to position translators
	for   (@{$self->{'visual_page_order'}}){ $_++ if $_ >= $position }
	splice @{$self->{'visual_page_order'}},  $position, 0, $position;
	$self->refresh_internal_page_order();
	$self->{'construction'} = 0;

	$self;
}

sub get_page_by_vis_nr {
	my ($self, $nr) = @_;
	return $self->GetSelection unless defined $nr;
	return 0 if $nr < $self->leftmost_page_pos() or $nr > $self->rightmost_page_pos();
	return $self->GetPage( $self->{'visual_page_order'}[ $nr ] );
}


sub unmount_events {
	my ($self) = @_;
	Wx::Event::EVT_AUINOTEBOOK_BEGIN_DRAG( $self, -1, sub {});
	Wx::Event::EVT_AUINOTEBOOK_END_DRAG  ( $self, -1, sub {});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED( $self, -1, sub {});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CLOSE  ( $self, -1, sub {});
}
sub mount_events {
	my ($self) = @_;
	#Wx::Event::EVT_SET_FOCUS ($self,  sub { print "focus--\n";$_[1]->Skip });
	Wx::Event::EVT_AUINOTEBOOK_BEGIN_DRAG( $self, $self, sub {
		my ($bar, $event ) = @_;
		$bar->{'DND_page_nr'} = $event->GetSelection;
	});
	Wx::Event::EVT_AUINOTEBOOK_END_DRAG($self, $self, sub {
		my ($bar, $event ) = @_;
		return unless defined $bar->{'DND_page_nr'};
		$bar->move_page_position_visually($bar->{'DND_page_nr'}, $event->GetSelection);
		$bar->{'DND_page_nr'} = undef;
		#focus_keep();      # loosing focus while dragging
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED( $self, $self, sub {
		my ($self, $event) = @_;
		$event->Skip if defined $event;
		return if $self->{'construction'};
		my $new_page = $self->GetPage( (defined $event) ? $event->GetSelection : $self->GetSelection);
		my $doc = Kephra::Document::Stash::set_active_doc( $new_page );
		app_window()->default_title_update();
		app_window()->SetStatusText( $doc->{'encoding'}, 1);
		Wx::Window::SetFocus( $new_page );
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CLOSE( $self, $self, sub {
		my ($bar, $event ) = @_; 
		$event->Veto;
		Kephra::API::document()->close();
	});# keep focus on editor even when klicking on tab bar
	#Wx::Event::EVT_LEFT_DOWN( $self, sub { Kephra::API::focus(Kephra::API::editor); });
	#Wx::Event::EVT_SET_FOCUS( $self, sub { my ($bar, $event ) = @_; $event->Skip; });
	$self;
}


sub raise_page    {
	my ($self, $pop) = @_; # can be Position Or Page (panel reference)
	my $position = int $pop eq $pop ? $pop : $self->GetPageIndex($pop);
	return unless $self->valid_page_pos( $position );
	# if just selecting the currrent, only tab drives focus nuts
	$self->SetSelection( $position ) unless $position == $self->GetSelection;
	my $panel = $self->GetPage($position);
	my $doc = Kephra::Document::Stash::set_active_doc( $panel );
	#focus ( $doc->{'active_editor'} );
	app_window()->default_title_update();
}


sub move_page_position_visually {          # for dnd only
	my ($self, $from, $to ) = @_;
	return unless $from >= 0 and $from < $self->GetPageCount;
	return unless $to >= 0 and $to < $self->GetPageCount;
	my $position = splice @{$self->{'visual_page_order'}}, $from, 1;
	splice @{$self->{'visual_page_order'}}, $to, 0, $position;
	$self->refresh_internal_page_order();
}

sub move_page_visually  {               # for movements by keyboard
	my ($self, $from, $to ) = @_;
	my $max = $self->GetPageCount - 1;
	return if $from < 0 or $from > $max;
	return if $to < 0 or $to > $max;
	return if $from == $to;

	my $pos = $self->{'visual_page_order'}[ $from ];
	my $page = $self->GetPage( $pos );
	my $label = $self->GetPageText( $pos );
	my $visual = $self->{'visual_page_order'};

	$self->unmount_events();
	$self->RemovePage( $pos );
	$self->InsertPage( $to, $page, $label);
	my $removed = splice @$visual, $from, 1;
	if ($from < $to) { for (@$visual) {$_-- if $_ > $removed and $_ <= $to} }
	else             { for (@$visual) {$_++ if $_ < $removed and $_ >= $to} }
	splice @$visual, $to, 0, $to;
	$self->{'visual_page_order'} = $visual;
	$self->refresh_internal_page_order();
	$self->SetSelection( $self->{'visual_page_order'}[$to] );
	$self->mount_events();
}


sub move_page_left        { my ($self) = @_;
	$self->move_page_visually ( $self->active_visual_pos, $self->next_page_pos_rot_left( $self->GetSelection ) );
}
sub move_page_right       { my ($self) = @_;
	$self->move_page_visually( $self->active_visual_pos, $self->next_page_pos_rot_right( $self->GetSelection ) );
}
sub move_page_leftmost    { my ($self) = @_;
	$self->move_page_visually( $self->active_visual_pos, $self->leftmost_page_pos );
}
sub move_page_rightmost   { my ($self) = @_;
	$self->move_page_visually( $self->active_visual_pos, $self->rightmost_page_pos );
}
sub raise_page_left      { my ($self) = @_;
	$self->raise_page( $self->next_page_pos_rot_left( $self->GetSelection ) );
}
sub raise_page_right     { my ($self) = @_;
	$self->raise_page( $self->next_page_pos_rot_right( $self->GetSelection ) );
}
sub raise_page_leftmost  { $_[0]->raise_page( $_[0]->leftmost_page_pos ) }
sub raise_page_rightmost { $_[0]->raise_page( $_[0]->rightmost_page_pos ) }

sub active_visual_pos     { $_[0]->{'internal_page_order'}[ $_[0]->GetSelection ] }
sub leftmost_page_pos     { 0 }
sub rightmost_page_pos    { $_[0]->GetPageCount() - 1 }
sub valid_page_pos        { 
	1 if $_[1] >= $_[0]->leftmost_page_pos and $_[1]<= $_[0]->rightmost_page_pos
}
sub next_page_pos_rot_left{
	my ($self) = @_; # take in position of internal order
	my $pos = $self->{'internal_page_order'}[ $_[1] ];
	$self->{'visual_page_order'}[$pos == 0 ? $self->rightmost_page_pos : $pos-1]
}
sub next_page_pos_rot_right{
	my ($self) = @_; # take in position of internal order
	my $pos = $self->{'internal_page_order'}[ $_[1] ];
	$self->{'visual_page_order'}[$pos == $self->rightmost_page_pos ? 0 : $pos+1]
}


sub raise_title { $_[0]->GetPageText( $_[0]->GetSelection ) }

sub set_page_title {
	my ($self, $label, $page) = @_;
	$page = $self->GetSelection unless defined $page;
	return warning("need a Kephra::App::Panel or valid position number") 
		unless is_panel($page) or (looks_like_number($page) and $self->valid_page_pos($page));
	my $found = $self->GetPageIndex($page) unless looks_like_number($page);
	my $position = looks_like_number($page) ? $page : $found; #&Wx::wxNOT_FOUND
	$self->SetPageText( $position, $label );
}


sub refresh_internal_page_order {       # sync visual_page_order index with internal_page_order after each change
	my ($self) = @_;
	my $visual = $self->{'visual_page_order'};
	return unless ref $visual eq ref [];
	my $internal;
	$internal->[ $visual->[$_] ] = $_ for 0 .. scalar @$visual - 1;
	$self->{'internal_page_order'} = $internal;
}


sub remove_page {
	my ($self, $page) = @_;
	my $internal_position = $self->GetPageIndex( $page );
	return warning("could not remove requested page $page") if $internal_position == -1;

	$self->{'construction'} = 1;
	$self->RemovePage( $internal_position );
	my $visual_position = $self->{'internal_page_order'}[$internal_position];
	my $visual = $self->{'visual_page_order'};
	splice @$visual, $visual_position, 1;
	for (@$visual) {$_-- if $_ >= $internal_position}
	$self->{'visual_page_order'} = $visual;
	$self->refresh_internal_page_order;
	$page->Reparent( app_window() );
	$self->{'construction'} = 0;
}

sub remove_all_pages {
	my ($self) = @_;
	$self->remove_page(0) while $self->GetPageCount;
}


sub Destroy {
	my ($self) = @_;
	#$_->del_instance($self) for Kephra::API::all_documents();
	$self->remove_all_pages();
	$self->SUPER::Destroy( );
	1;
}

1;

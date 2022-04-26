use v5.12;
use warnings;

package Kephra::App::Editor;
use experimental qw/switch/;
use Wx qw/ :everything /;
use Wx::STC;
use Wx::DND;
#use Wx::Scintilla;
our @ISA = 'Wx::StyledTextCtrl';

sub is_empty { not shift->GetTextLength }

sub new {
	my( $class, $parent, $style, $visible) = @_;
	my $self = $class->SUPER::new($parent, -1,[-1,-1],[-1,-1]);
	$self->load_font();  # before setting highlighting
	$self->set_colors(); # after highlight
	$self->set_margin();
	$self->mount_events();
	$self->set_tab_size(4);
	$self->set_tab_usage(1);
	$self->SetScrollWidth(300);
	return $self;
}

sub reset_text { # start life with this text
	my ($self, $text) = @_;
	$text = '' unless defined $text;
	$self->SetText($text);
	$self->EmptyUndoBuffer;
	$self->SetSavePoint;
}

sub insert_text {
	my ($self, $text, $pos) = @_;
	$pos = $self->GetCurrentPos unless defined $pos;
	$self->InsertText($pos, $text);
}


sub mount_events {
	my ($self, @which) = @_;
	$self->DragAcceptFiles(1) if $^O eq 'MSWin32'; # enable drop files on win
	#$self->SetDropTarget( Kephra::App::Editor::TextDropTarget->new($self) );

	Wx::Event::EVT_KEY_DOWN($self , sub {
		my ($ed, $event) = @_;
		my $code = $event->GetUnicodeKey;
		my $shift= $event->ShiftDown   ? 1 : 0;
		my $ctrl = $event->ControlDown ? 1 : 0;
		my $alt  = $event->AltDown     ? 1 : 0;
		my $doc = Kephra::API::document();
		my $bar = Kephra::API::doc_bar();
		if   ($shift and $ctrl and $code == &Wx::WXK_PAGEUP)  {$bar->move_page_left() }
		elsif($shift and $ctrl and $code == &Wx::WXK_PAGEDOWN){$bar->move_page_right() }
		elsif(           $ctrl and $code == &Wx::WXK_PAGEUP)  {$bar->raise_page_left() }
		elsif(           $ctrl and $code == &Wx::WXK_PAGEDOWN){$bar->raise_page_right() }
		elsif($shift and $ctrl and $code == ord('G'))         {$ed->goto_last_edit() }
		elsif(           $ctrl and $code == ord('M'))         { $doc->rot_syntaxmode() }
		elsif(           $ctrl and $code == ord('N'))         { Kephra::Document::new() }
		elsif($shift and $ctrl and $code == ord('O'))         {$doc->reopen() }
		elsif(           $ctrl and $code == ord('O'))         {$doc->open() }
		elsif($shift and $ctrl and $code == ord('S'))         {$doc->save_as() }
		elsif(           $ctrl and $code == ord('S'))         {$doc->save() }
		elsif(           $ctrl and $code == ord('Q'))         {$doc->close() }
		elsif(            $alt and $code == ord('Q'))         {Kephra::App::close() }
		else {$event->Skip  }
	});
	Wx::Event::EVT_STC_UPDATEUI($self, -1, sub {
		Kephra::API::app_window()->SetStatusText( ($self->GetCurrentLine + 1).':'.$self->GetCurrentPos, 0);
		#Kephra::API::document()->{'cursor_pos'} = $self->GetCurrentPos;
	});
	Wx::Event::EVT_STC_CHANGE       ($self, -1, sub {
		my ($ed, $event) = @_;
		$ed->{'change_pos'} = $ed->GetCurrentPos;
		$event->Skip;
	} );
	#my $key = Kephra::API::KeyMap::keycode_from_event($event);
	#if (Kephra::API::KeyMap::keycode_is_registered($key)){
	#my $cmd = Kephra::API::KeyMap::cmd_from_keycode($key);
	#Kephra::API::Command::run( $cmd );
	#$ed->GetStyleAt($ed->GetCurrentPos);
	Wx::Event::EVT_STC_SAVEPOINTREACHED($self, -1, sub {
		my $doc = Kephra::API::document();
		Kephra::API::doc_bar()->set_page_title( $doc->{'title'}, $doc->{'panel'} ); # prevent rewrite the still inactive tab title
		Kephra::API::app_window()->default_title_update();
	});
	Wx::Event::EVT_STC_SAVEPOINTLEFT($self, -1, sub {
		my $doc = Kephra::API::document();
		return unless ref $doc;
		#return unless $doc;
		Kephra::API::doc_bar()->set_page_title( $doc->{'title'}.' *', $doc->{'panel'} );
		Kephra::API::app_window()->default_title_update();
	});
	Wx::Event::EVT_SET_FOCUS( $self, sub {
		my ($ed, $event ) = @_;
		$event->Skip;
	});
}


sub create_color { Wx::Colour->new(@_) }

sub set_margin {
	my ($self, $style) = @_;

	if (not defined $style or not $style or $style eq 'default') {
		$self->SetMarginType( 0, &Wx::wxSTC_MARGIN_SYMBOL );
		$self->SetMarginType( 1, &Wx::wxSTC_MARGIN_NUMBER );
		$self->SetMarginType( 2, &Wx::wxSTC_MARGIN_SYMBOL );
		$self->SetMarginMask( 0, 0x01FFFFFF );
		$self->SetMarginMask( 1, 0 );
		$self->SetMarginMask( 2, &Wx::wxSTC_MASK_FOLDERS );
		$self->SetMarginSensitive( 0, 1 );
		$self->SetMarginSensitive( 1, 1 );
		$self->SetMarginSensitive( 2, 1 );
		$self->StyleSetForeground(&Wx::wxSTC_STYLE_LINENUMBER, create_color(123,123,137));
		$self->StyleSetBackground(&Wx::wxSTC_STYLE_LINENUMBER, create_color(226,226,222));
		$self->SetMarginWidth(0,  0);
		$self->SetMarginWidth(1, 41);
		$self->SetMarginWidth(2,  0);
		# extra text margin
	}
	elsif ($style eq 'no') { $self->SetMarginWidth($_, 0) for 1..3 }

	# extra margin left and right inside the white text area
	$self->SetMargins(2, 2);
	$self;
}


sub goto_last_edit {
	my ($self) = @_;
	$self->SetSelection($self->{'change_pos'}, $self->{'change_pos'});
}

sub set_tab_size {
	my ($self, $size) = @_;
	#$size *= 2 if $^O eq 'darwin';
	$self->SetTabWidth($size);
	$self->SetIndent($size);
	$self->SetHighlightGuide($size);
}
sub set_tab_usage {
	my ($self, $usage) = @_;
	$self->SetUseTabs($usage);
}

sub set_colors {
	my $self = shift;
	$self->SetCaretLineBack( create_color(250,245,185) );
	#$self->SetCaretPeriod( 500 );
	#$self->SetCaretWidth( 2 );
	$self->SetCaretForeground( create_color(0,0,255) );
	$self->SetCaretLineVisible(1);
	$self->SetSelForeground( 1, create_color(243,243,243) );
	$self->SetSelBackground( 1, create_color(0, 17, 119) );
	$self->SetWhitespaceForeground( 1, create_color(204, 204, 153) );
	$self->SetViewWhiteSpace(1);

	$self->SetEdgeColour( create_color(200,200,255) );
	$self->SetEdgeColumn( 80 );
	$self->SetEdgeMode( &Wx::wxSTC_EDGE_LINE );
}

sub load_font {
	my ($self, $font) = @_;
	my ( $fontweight, $fontstyle ) = ( &Wx::wxNORMAL, &Wx::wxNORMAL );
	$font = {
		family => $^O eq 'darwin' ? 'Andale Mono' : 'Courier New', # old default
		#family => 'DejaVu Sans Mono', # new
		size => $^O eq 'darwin' ? 13 : 11,
		style => 'normal',
		weight => 'normal',    
	} unless defined $font;
	#my $font = _config()->{font};
	$fontweight = &Wx::wxLIGHT  if $font->{weight} eq 'light';
	$fontweight = &Wx::wxBOLD   if $font->{weight} eq 'bold';
	$fontstyle  = &Wx::wxSLANT  if $font->{style}  eq 'slant';
	$fontstyle  = &Wx::wxITALIC if $font->{style}  eq 'italic';
	my $wx_font = Wx::Font->new( 
		$font->{size}, &Wx::wxDEFAULT, $fontstyle, $fontweight, 0, $font->{family}
	);
	$self->StyleSetFont( &Wx::wxSTC_STYLE_DEFAULT, $wx_font ) if $wx_font->Ok > 0;
}

sub focus {  Kephra::API::focus( $_[0] ) }

1;

__END__

$self->SetIndicatorCurrent( $c);
$self->IndicatorFillRange( $start, $len );
$self->IndicatorClearRange( 0, $len )
	#Wx::Event::EVT_STC_STYLENEEDED($self, sub{}) 
	#Wx::Event::EVT_STC_CHARADDED($self, sub {});
	#Wx::Event::EVT_STC_ROMODIFYATTEMPT($self, sub{}) 
	#Wx::Event::EVT_STC_KEY($self, sub{}) 
	#Wx::Event::EVT_STC_DOUBLECLICK($self, sub{}) 
	Wx::Event::EVT_STC_UPDATEUI($self, -1, sub { #my ($ed, $event) = @_; $event->Skip; print "change \n"; });
	#Wx::Event::EVT_STC_MODIFIED($self, sub {});
	#Wx::Event::EVT_STC_MACRORECORD($self, sub{}) 
	#Wx::Event::EVT_STC_MARGINCLICK($self, sub{}) 
	#Wx::Event::EVT_STC_NEEDSHOWN($self, sub {});
	#Wx::Event::EVT_STC_PAINTED($self, sub{}) 
	#Wx::Event::EVT_STC_USERLISTSELECTION($self, sub{}) 
	#Wx::Event::EVT_STC_UR$selfROPPED($self, sub {});
	#Wx::Event::EVT_STC_DWELLSTART($self, sub{}) 
	#Wx::Event::EVT_STC_DWELLEND($self, sub{}) 
	#Wx::Event::EVT_STC_START_DRAG($self, sub{}) 
	#Wx::Event::EVT_STC_DRAG_OVER($self, sub{}) 
	#Wx::Event::EVT_STC_DO_DROP($self, sub {});
	#Wx::Event::EVT_STC_ZOOM($self, sub{}) 
	#Wx::Event::EVT_STC_HOTSPOT_CLICK($self, sub{}) 
	#Wx::Event::EVT_STC_HOTSPOT_DCLICK($self, sub{}) 
	#Wx::Event::EVT_STC_CALLTIP_CLICK($self, sub{}) 
	#Wx::Event::EVT_STC_AUTOCOMP_SELECTION($self, sub{})
	#$self->SetAcceleratorTable( Wx::AcceleratorTable->new() );
	#Wx::Event::EVT_MENU( $self, 1000, sub { $_[1]->Skip; } );
	#Wx::Event::EVT_STC_SAVEPOINTREACHED($self, -1, \&Kephra::File::savepoint_reached);
	#Wx::Event::EVT_STC_SAVEPOINTLEFT($self, -1, \&Kephra::File::savepoint_left);
	$self->SetAcceleratorTable(
	Wx::AcceleratorTable->new( [&Wx::wxACCEL_CTRL, ord 'n', 1000], ));
